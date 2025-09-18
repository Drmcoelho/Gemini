import os, sqlite3, typing as t
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles

DB_PATH = os.environ.get("DB_PATH", "/data/loinc.sqlite")
app = FastAPI(title="LOINC Web", version="1.0.0")
templates = Jinja2Templates(directory="templates")

os.makedirs("/data", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

def get_conn():
    if not os.path.exists(DB_PATH):
        raise FileNotFoundError(f"DB not found at {DB_PATH}. Did you import LOINC?")
    con = sqlite3.connect(DB_PATH)
    con.row_factory = sqlite3.Row
    return con

@app.get("/api/ping")
def ping():
    return {"ok": True}

@app.get("/api/loinc/code/{code}")
def get_code(code: str):
    with get_conn() as con:
        cur = con.execute("SELECT * FROM loinc WHERE code = ?", (code,))
        row = cur.fetchone()
        if not row:
            raise HTTPException(404, "LOINC code not found")
        return dict(row)

@app.get("/api/loinc/search")
def search_loinc(q: str = Query(..., min_length=1, max_length=100), limit: int = 25, offset: int = 0):
    with get_conn() as con:
        # Use FTS when available; fallback to LIKE
        has_fts = con.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='loinc_fts'").fetchone() is not None
        if has_fts:
            sql = "SELECT l.* FROM loinc l JOIN loinc_fts f ON l.rowid=f.rowid WHERE loinc_fts MATCH ? LIMIT ? OFFSET ?"
            params = (q.strip(), limit, offset)
        else:
            sql = "SELECT * FROM loinc WHERE long_name LIKE ? OR component LIKE ? LIMIT ? OFFSET ?"
            params = (f"%{q}%", f"%{q}%", limit, offset)
        rows = [dict(r) for r in con.execute(sql, params).fetchall()]
        return {"items": rows, "count": len(rows), "limit": limit, "offset": offset}

@app.get("/api/loinc/suggest")
def suggest(prefix: str = Query(..., min_length=1), limit: int = 10):
    pref = prefix.strip() + "%"
    with get_conn() as con:
        rows = [r["code"] for r in con.execute("SELECT code FROM loinc WHERE code LIKE ? ORDER BY code LIMIT ?", (pref, limit)).fetchall()]
        names = [r["long_name"] for r in con.execute("SELECT long_name FROM loinc WHERE long_name LIKE ? ORDER BY long_name LIMIT ?", (pref, limit)).fetchall()]
        return {"codes": rows, "names": names}

# ---- UI (HTMX) ----
@app.get("/", response_class=HTMLResponse)
def index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/ui/search", response_class=HTMLResponse)
def ui_search(request: Request, q: str = Query(...), limit: int = 25):
    with get_conn() as con:
        has_fts = con.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='loinc_fts'").fetchone() is not None
        if has_fts:
            sql = "SELECT l.code, l.long_name, l.component, l.property, l.time_aspct, l.system, l.scale_typ, l.method_typ, l.class FROM loinc l JOIN loinc_fts f ON l.rowid=f.rowid WHERE loinc_fts MATCH ? LIMIT ?"
            params = (q.strip(), limit)
        else:
            sql = "SELECT code,long_name,component,property,time_aspct,system,scale_typ,method_typ,class FROM loinc WHERE long_name LIKE ? OR component LIKE ? LIMIT ?"
            params = (f"%{q}%", f"%{q}%", limit)
        rows = [dict(r) for r in con.execute(sql, params).fetchall()]
    return templates.TemplateResponse("_rows.html", {"request": request, "rows": rows})
