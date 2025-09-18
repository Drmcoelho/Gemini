from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import subprocess
import os

from fastapi.middleware.cors import CORSMiddleware

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

    # Construir o comando para executar a automação
    # Ex: ./gemx.sh auto run automations/rx_brief.yaml --prompt "..."
    command = [
        gemx_script_path,
        "auto",
        "run",
        f"automations/{request.automation_name}.yaml",
        "--prompt",
        request.prompt,
    ]
    command.extend(request.extra_args)

    try:
        # Executar o comando gemx.sh
        process = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=True,
            cwd=os.path.join(os.path.dirname(__file__), "..") # Executar do diretório Gemini_v2
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

@app.get("/automations")
async def list_automations():
    """
    Lista todas as automações disponíveis no Megapack.
    """
    automations_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "automations"))
    if not os.path.exists(automations_dir):
        raise HTTPException(status_code=500, detail=f"Diretório de automações não encontrado em {automations_dir}")

    yaml_files = glob.glob(os.path.join(automations_dir, "*.yaml"))
    automation_names = [os.path.splitext(os.path.basename(f))[0] for f in yaml_files]
    return {"automations": sorted(automation_names)}

@app.get("/")
async def root():
    return {"message": "Bem-vindo à API Web do Gemini Megapack v2. Acesse /docs para a documentação da API."}
