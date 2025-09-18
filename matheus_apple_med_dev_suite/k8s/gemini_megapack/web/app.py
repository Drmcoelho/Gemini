# web/app.py
import os, subprocess, json, pathlib, time
from typing import Optional, List
from fastapi import FastAPI, Depends, HTTPException, status, Request
from starlette.middleware.sessions import SessionMiddleware
from starlette.responses import RedirectResponse
from authlib.integrations.starlette_client import OAuth
from fastapi.responses import JSONResponse, PlainTextResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from prometheus_client import CollectorRegistry, Counter, generate_latest, CONTENT_TYPE_LATEST

APP_ROOT = pathlib.Path(__file__).resolve().parents[1]
HOME = pathlib.Path(os.environ.get("HOME", str(APP_ROOT / "home")))
GEMX_HOME = HOME / ".config" / "gemx"
HIST_DIR = GEMX_HOME / "history"
LOG_DIR = GEMX_HOME / "logs"
AUTOS_DIR = APP_ROOT / "automations"
FLOWS_DIR = APP_ROOT / "flows"

os.makedirs(HIST_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

WEB_USER = os.environ.get("WEB_USER", "")
WEB_PASS = os.environ.get("WEB_PASS", "")

def basic_auth(request: Request):
    # OAuth session check first (if configured)
    if GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET:
        user = request.session.get('user')
        if user:
            return
        # no session -> require login
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='login required via OAuth', headers={'WWW-Authenticate':'Bearer'})

    # Fallback: Basic Auth (only if WEB_USER/PASS set)
    if not WEB_USER and not WEB_PASS:
        return
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Basic "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="auth required", headers={"WWW-Authenticate":"Basic"})
    import base64
    try:
        userpass = base64.b64decode(auth.split(" ",1)[1]).decode("utf-8")
        u,p = userpass.split(":",1)
    except Exception:
        raise HTTPException(status_code=401, detail="bad auth header", headers={"WWW-Authenticate":"Basic"})
    if u != WEB_USER or p != WEB_PASS:
        raise HTTPException(status_code=401, detail="invalid credentials", headers={"WWW-Authenticate":"Basic"})

app = FastAPI(title="Gemini Megapack — Web")
# Session (cookie) for OAuth
SECRET_KEY = os.environ.get('WEB_SECRET_KEY','dev-secret-change')
app.add_middleware(SessionMiddleware, secret_key=SECRET_KEY, same_site='lax', https_only=False)

# OAuth (Google) optional
GOOGLE_CLIENT_ID = os.environ.get('GOOGLE_CLIENT_ID','')
GOOGLE_CLIENT_SECRET = os.environ.get('GOOGLE_CLIENT_SECRET','')
OAUTH_CALLBACK_URL = os.environ.get('OAUTH_CALLBACK_URL', '')  # e.g., https://your.domain/auth/callback
ALLOWED_EMAILS = set([e.strip() for e in os.environ.get('ALLOWED_EMAILS','').split(',') if e.strip()])
ALLOWED_DOMAIN = os.environ.get('ALLOWED_DOMAIN','')
oauth = OAuth()
if GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET:
    oauth.register(
        name='google',
        client_id=GOOGLE_CLIENT_ID,
        client_secret=GOOGLE_CLIENT_SECRET,
        server_metadata_url='https://accounts.google.com/.well-known/openid-configuration',
        client_kwargs={'scope': 'openid email profile'}
    )


# Prometheus
REG = CollectorRegistry()
REQS = Counter("gemx_web_requests_total","web requests",["path"], registry=REG)
CMDS = Counter("gemx_commands_total","gemx CLI invocations",["cmd"], registry=REG)

@app.middleware("http")
async def metrics_mw(request: Request, call_next):
    REQS.labels(request.url.path).inc()
    return await call_next(request)

class GenIn(BaseModel):
    prompt: str
    timeout: Optional[int] = 90

def run_cmd(args: list[str], timeout: int = 120) -> tuple[int,str,str]:
    try:
        p = subprocess.Popen(args, cwd=str(APP_ROOT), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            out, err = p.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            p.kill()
            return 124, "", "timeout"
        return p.returncode, out, err
    except FileNotFoundError as e:
        return 127, "", str(e)

@app.get("/healthz")
def health():
    return {"ok": True}

@app.get("/api/history", dependencies=[Depends(basic_auth)])
def history_list(limit: int = 50):
    items = []
    for p in sorted(HIST_DIR.glob("sess_*.md"), reverse=True)[:limit]:
        items.append({"name": p.name, "size": p.stat().st_size, "mtime": int(p.stat().st_mtime)})
    return {"items": items}

@app.get("/api/audit/tail", dependencies=[Depends(basic_auth)])
def audit_tail(lines: int = 200):
    # tail last audit-*.jsonl by date (UTC)
    files = sorted(LOG_DIR.glob("audit-*.jsonl"))
    if not files:
        return {"lines": []}
    path = files[-1]
    try:
        with open(path, "rb") as f:
            f.seek(0,2); size=f.tell()
            block = 8192; data=b""; lns=[]
            while size > 0 and len(lns) <= lines:
                step = block if size - block > 0 else size
                f.seek(size-step)
                data = f.read(step) + data
                size -= step
                lns = data.splitlines()
            lns = [ln.decode("utf-8","ignore") for ln in lns[-lines:]]
        return {"file": path.name, "lines": lns}
    except Exception as e:
        raise HTTPException(500, str(e))

@app.post("/api/gen", dependencies=[Depends(basic_auth)])
def api_gen(payload: GenIn):
    CMDS.labels("gen").inc()
    # Ensure gemini binary available
    gemx = str(APP_ROOT / "gemx.sh")
    rc, out, err = run_cmd([gemx, "gen", "--prompt", payload.prompt], timeout=min(max(payload.timeout, 5), 300))
    if rc == 127:
        raise HTTPException(409, "binário necessário não encontrado (gemini/gmini). Monte-o em /usr/local/bin/gemini ou configure GEMINI_BIN.")
    if rc != 0:
        return JSONResponse(status_code=500, content={"rc": rc, "stdout": out, "stderr": err})
    return {"rc": rc, "stdout": out}

class FlowIn(BaseModel):
    path: str
    timeout: Optional[int] = 300

@app.post("/api/flow", dependencies=[Depends(basic_auth)])
def api_flow(payload: FlowIn):
    CMDS.labels("flow").inc()
    flow_path = (APP_ROOT / payload.path).resolve()
    if not flow_path.exists():
        raise HTTPException(404, "flow não encontrado")
    rc, out, err = run_cmd([str(APP_ROOT / "gemx.sh"), "flow", str(flow_path.relative_to(APP_ROOT))], timeout=min(max(payload.timeout or 60, 10), 1800))
    if rc != 0:
        return JSONResponse(status_code=500, content={"rc": rc, "stdout": out, "stderr": err})
    return {"rc": rc, "stdout": out}

@app.get("/metrics")
def metrics():
    return PlainTextResponse(generate_latest(REG), media_type=CONTENT_TYPE_LATEST)

# static index
static_dir = pathlib.Path(__file__).parent / "static"
app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")


@app.get('/auth/login')
async def auth_login(request: Request):
    if not (GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET):
        raise HTTPException(404, 'OAuth not configured')
    redirect_uri = OAUTH_CALLBACK_URL or (str(request.base_url).rstrip('/') + '/auth/callback')
    return await oauth.google.authorize_redirect(request, redirect_uri)

@app.get('/auth/callback')
async def auth_callback(request: Request):
    if not (GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET):
        raise HTTPException(404, 'OAuth not configured')
    token = await oauth.google.authorize_access_token(request)
    userinfo = token.get('userinfo')
    if not userinfo:
        
        raise HTTPException(401, 'no userinfo from provider')
    email = userinfo.get('email','')
    if ALLOWED_EMAILS and email not in ALLOWED_EMAILS:
        raise HTTPException(403, 'email not allowed')
    if ALLOWED_DOMAIN and not email.endswith('@' + ALLOWED_DOMAIN):
        raise HTTPException(403, 'domain not allowed')
    request.session['user'] = {
        'email': email,
        'name': userinfo.get('name','')
    }
    return RedirectResponse('/')

@app.get('/logout')
async def logout(request: Request):
    request.session.clear()
    return RedirectResponse('/')


@app.get("/", response_class=HTMLResponse)
def index():
    try:
        with open(static_dir / "index.html", "r", encoding="utf-8") as f:
            return HTMLResponse(f.read())
    except Exception:
        return HTMLResponse("<h1>Gemini Megapack — Web</h1><p>Instale assets em /static</p>")
