import subprocess
import typer
from rich.console import Console

app = typer.Typer()
console = Console()

def find_gemini_binary():
    # Simple version of resolve_bin from the shell script
    for binary in ["gemini", "gmini"]:
        try:
            subprocess.run(["which", binary], check=True, capture_output=True)
            return binary
        except (subprocess.CalledProcessError, FileNotFoundError):
            continue
    return None

@app.command()
def setup():
    """Verifica dependências e o binário do Gemini."""
    console.print("[bold cyan]Verificando dependências...[/bold cyan]")
    
    jq_found = False
    try:
        subprocess.run(["which", "jq"], check=True, capture_output=True)
        jq_found = True
        console.print("[green]✓[/green] jq encontrado.")
    except (subprocess.CalledProcessError, FileNotFoundError):
        console.print("[red]✗[/red] jq não encontrado. Por favor, instale-o.")

    gemini_bin = find_gemini_binary()
    if gemini_bin:
        console.print(f"[green]✓[/green] Binário do Gemini encontrado: [bold]{gemini_bin}[/bold]")
    else:
        console.print("[red]✗[/red] Nenhum binário ('gemini' or 'gmini') encontrado no PATH.")

@app.command(name="models")
def list_models():
    """Lista os modelos disponíveis através do binário do Gemini."""
    gemini_bin = find_gemini_binary()
    if not gemini_bin:
        console.print("[red]Erro:[/red] Binário do Gemini não encontrado.")
        raise typer.Exit(1)
    
    console.print(f"[cyan]Executando: [bold]{gemini_bin} model list[/bold][/cyan]")
    
    # Tenta 'model list' e depois 'models' como fallback
    try:
        result = subprocess.run([gemini_bin, "model", "list"], capture_output=True, text=True)
        if result.returncode != 0:
             result = subprocess.run([gemini_bin, "models"], capture_output=True, text=True, check=True)
        
        console.print(result.stdout)
        if result.stderr:
            console.print(f"[yellow]Stderr:[/yellow]\n{result.stderr}")
            
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        console.print(f"[red]Falha ao executar o comando do Gemini:[/red]\n{e}")
        raise typer.Exit(1)

if __name__ == "__main__":
    app()
