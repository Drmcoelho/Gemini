from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import subprocess
import os

from fastapi.middleware.cors import CORSMiddleware
from typing import List, Tuple, Optional, Dict

app = FastAPI(
    title="Gemini Megapack v2 Web API",
    description="API para interagir com as automações do Gemini Megapack v2.",
    version="0.1.0",
)

# Adicionar middleware CORS para permitir requisições do frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permitir todas as origens para desenvolvimento
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class AutomationRequest(BaseModel):
    automation_name: str
    prompt: str
    extra_args: list[str] = []

@app.post("/automations/run")
async def run_automation(request: AutomationRequest):
    """
    Executa uma automação do Gemini Megapack v2.
    """
    # Caminho para o script gemx.sh (assumindo que está no diretório pai de gemx_web)
    gemx_script_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "gemx.sh"))
    
    if not os.path.exists(gemx_script_path):
        raise HTTPException(status_code=500, detail=f"gemx.sh script not found at {gemx_script_path}")

    # Resolver caminho seguro do YAML (suporta subpastas e múltiplas bases)
    target_yaml = _safe_automation_path(request.automation_name)

    # Construir o comando para executar a automação
    # Ex: ./gemx.sh auto run automations/rx_brief.yaml --prompt "..."
    # Não passar --prompt para evitar conflito com geração posicional no gemini CLI.
    # Em vez disso, usamos a variável de ambiente GEMX_PROMPT para o wrapper consumir.
    command = [
        gemx_script_path,
        "auto",
        "run",
        target_yaml,
    ]
    command.extend(request.extra_args)

    try:
        # Executar o comando gemx.sh
        env = os.environ.copy()
        env["GEMX_PROMPT"] = request.prompt or ""
        env["GEMX_QUIET"] = "1"
        process = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=True,
            cwd=os.path.join(os.path.dirname(__file__), ".."), # Executar do diretório Gemini_v2
            env=env,
        )
        return {"status": "success", "output": process.stdout.strip()}
    except subprocess.CalledProcessError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao executar automação: {e.stderr.strip()}"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro inesperado: {str(e)}")

import glob
from typing import Dict, Tuple, Optional


def _project_dirs() -> Tuple[str, str]:
    """Retorna (dir_gemini_v2, dir_repo_root)."""
    gemv2_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    repo_root = os.path.abspath(os.path.join(gemv2_dir, ".."))
    return gemv2_dir, repo_root


def _automation_roots() -> list[str]:
    """Lista de diretórios de automations. Controlado por GEMX_AUTOMATIONS_DIRS.
    Formatos aceitos: separado por ':' ou ','. Defaults: Gemini_v2/automations e <repo>/automations
    """
    env = os.environ.get("GEMX_AUTOMATIONS_DIRS", "").strip()
    gemv2_dir, repo_root = _project_dirs()
    defaults = [
        os.path.join(gemv2_dir, "automations"),
        os.path.join(repo_root, "automations"),
    ]
    roots: list[str] = []
    if env:
        parts = [p for raw in env.split(":" if ":" in env else ",") for p in [raw.strip()] if p]
        for p in parts:
            ap = os.path.abspath(p)
            if os.path.isdir(ap):
                roots.append(ap)
    for d in defaults:
        if os.path.isdir(d) and d not in roots:
            roots.append(d)
    return roots

def _automations_base_dirs() -> List[str]:
    """Retorna a lista de diretórios base onde buscar automations.
    Por padrão inclui Gemini_v2/automations e, se existir, /workspaces/Gemini/automations.
    Pode ser sobrescrito por GEMX_AUTOMATIONS_DIRS (separado por ':').
    """
    env_dirs = os.environ.get("GEMX_AUTOMATIONS_DIRS")
    if env_dirs:
        bases = [os.path.abspath(d) for d in env_dirs.split(":") if d.strip()]
    else:
        here = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        bases = [os.path.join(here, "automations")]
        root_auto = os.path.abspath(os.path.join(here, "..", "automations"))
        if os.path.isdir(root_auto):
            bases.append(root_auto)
    # Dedup preservando ordem
    seen = set()
    uniq: List[str] = []
    for b in bases:
        if b not in seen and os.path.isdir(b):
            uniq.append(b); seen.add(b)
    return uniq


@app.get("/automations")
async def list_automations():
    """
    Lista todas as automações disponíveis no Megapack (inclui subpastas como 'matheus').
    Retorna caminhos relativos sem a extensão .yaml.
    """
    bases = _automations_base_dirs()
    all_names: set[str] = set()
    for base in bases:
        yaml_files: List[str] = [
            os.path.relpath(p, base)
            for p in glob.glob(os.path.join(base, "**", "*.yaml"), recursive=True)
        ]
        for p in yaml_files:
            name = os.path.splitext(p)[0].replace(os.sep, "/")
            all_names.add(name)
    return {"automations": sorted(all_names)}

def _safe_automation_path(name: str) -> str:
    """Resolve nome (com subpastas) para caminho seguro dentro das bases de automations.
    Bloqueia path traversal e exige que o arquivo exista em alguma base.
    """
    norm = name.replace("\\", "/").lstrip("/.")
    bases = _automations_base_dirs()
    candidates: List[str] = []
    for base in bases:
        tgt = os.path.abspath(os.path.join(base, f"{norm}.yaml"))
        # garantir que está sob a base
        if not tgt.startswith(base + os.sep):
            continue
        candidates.append(tgt)
    for c in candidates:
        if os.path.exists(c):
            return c
    raise HTTPException(status_code=404, detail=f"Automação '{name}' não encontrada em bases: {bases}")


def _read_yaml(path: str) -> Optional[Dict]:
    try:
        import yaml  # type: ignore
    except Exception:
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)  # type: ignore
    except Exception:
        return None


@app.get("/automations/{name}")
async def automation_info(name: str):
    """Retorna metadados básicos da automação (model, temperature, prompt presence)."""
    target = _safe_automation_path(name)
    data = _read_yaml(target)
    info: Dict[str, Optional[str | float | bool]] = {
        "name": name,
        "path": target,
        "model": None,
        "temperature": None,
        "has_input_placeholder": None,
    }
    if data:
        model = data.get("model") if isinstance(data, dict) else None
        temp = data.get("temperature") if isinstance(data, dict) else None
        prompt = data.get("prompt") if isinstance(data, dict) else None
        info.update(
            {
                "model": model if isinstance(model, str) else None,
                "temperature": float(temp) if isinstance(temp, (int, float)) else None,
                "has_input_placeholder": ("{{INPUT}}" in prompt) if isinstance(prompt, str) else False,
            }
        )
    return info

@app.get("/")
async def root():
    return {"message": "Bem-vindo à API Web do Gemini Megapack v2. Acesse /docs para a documentação da API."}

@app.get("/health")
async def health():
    """Endpoint de healthcheck simples para o frontend verificar disponibilidade do backend."""
    return {"status": "ok"}
