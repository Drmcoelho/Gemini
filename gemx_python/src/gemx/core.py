# Funções principais do core da aplicação
import subprocess
import shlex
from . import config
from rich.console import Console
from typing import List

console = Console()

def find_gemini_binary():
    """Encontra o binário 'gemini' ou 'gmini' no PATH."""
    for binary in ["gemini", "gmini"]:
        try:
            subprocess.run(["which", binary], check=True, capture_output=True)
            return binary
        except (subprocess.CalledProcessError, FileNotFoundError):
            continue
    return None

def _build_gemini_args() -> List[str]:
    """Constrói a lista de argumentos para chamar o binário do Gemini."""
    args = [
        "generate",
        "--model", config.STATE.model,
        "--temperature", str(config.STATE.temperature),
    ]
    if config.STATE.system:
        args.extend(["--system", config.STATE.system])
    return args

def get_generation(prompt: str) -> str:
    """Executa o Gemini e captura a saída como uma string."""
    gemini_bin = find_gemini_binary()
    if not gemini_bin:
        console.print("[red]Erro:[/red] Binário do Gemini não encontrado.")
        return ""

    args = [gemini_bin] + _build_gemini_args()
    # Construímos o comando para ser executado explicitamente pelo bash
    cmd_string = " ".join(map(shlex.quote, args))
    bash_cmd = f"bash -c {shlex.quote(cmd_string)}"

    console.print(f"[cyan]Gerando resposta com o modelo [bold]{config.STATE.model}[/bold]...[/cyan]")
    
    try:
        result = subprocess.run(bash_cmd, input=prompt, capture_output=True, text=True, check=True, shell=True)
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        console.print(f"[red]Falha ao executar o comando do Gemini:[/red]\n{e}")
        return ""

def run_generation(prompt: str):
    """Executa o comando de geração do Gemini e exibe a saída diretamente."""
    gemini_bin = find_gemini_binary()
    if not gemini_bin:
        console.print("[red]Erro:[/red] Binário do Gemini não encontrado.")
        return

    args = [gemini_bin] + _build_gemini_args()
    cmd_string = " ".join(map(shlex.quote, args))
    bash_cmd = f"bash -c {shlex.quote(cmd_string)}"

    console.print(f"[cyan]Executando com o modelo [bold]{config.STATE.model}[/bold] (temp: {config.STATE.temperature})...[/cyan]")
    
    try:
        subprocess.run(bash_cmd, input=prompt, text=True, shell=True)
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        console.print(f"[red]Falha ao executar o comando do Gemini:[/red]\n{e}")
