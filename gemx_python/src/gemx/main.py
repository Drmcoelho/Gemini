import subprocess
import typer
from rich.console import Console
from typing_extensions import Annotated

from . import config
from . import others
from . import core

# --- App Setup ---
app = typer.Typer(help="O sucessor do gemx.sh, em Python.")
console = Console()

profile_app = typer.Typer(name="profile", help="Gerencia os perfis de configuração.")
app.add_typer(profile_app)

# --- Automation Constants ---
META_PROMPT_TEMPLATE = """
Como um especialista em automação do ecossistema Apple, sua tarefa é gerar um script para cumprir o objetivo do usuário.
O objetivo do usuário é: '{user_prompt}'.

Com base neste objetivo, gere um único, completo e executável AppleScript.
- O script deve ser robusto e incluir tratamento de erros quando apropriado.
- Não inclua nenhuma explicação, comentários ou formatação markdown.
- Sua resposta inteira deve ser APENAS o código AppleScript bruto.
- Exemplo para 'abrir notas': `tell application "Notes" to activate`
"""

# --- CLI Commands ---
@app.command()
def setup():
    """Verifica dependências, o binário e a configuração do Gemini."""
    console.print("[bold cyan]Verificando ambiente gemx...[/bold cyan]")
    
    # 1. Check dependencies
    try:
        subprocess.run(["which", "jq"], check=True, capture_output=True)
        console.print("[green]✓[/green] Dependência 'jq' encontrada.")
    except (subprocess.CalledProcessError, FileNotFoundError):
        console.print("[red]✗[/red] Dependência 'jq' não encontrada. Por favor, instale-a.")

    # 2. Check gemini binary
    gemini_bin = core.find_gemini_binary()
    if gemini_bin:
        console.print(f"[green]✓[/green] Binário do Gemini encontrado: [bold]{gemini_bin}[/bold]")
    else:
        console.print("[red]✗[/red] Nenhum binário ('gemini' or 'gmini') encontrado no PATH.")

    # 3. Check config file and show default model
    conf = config.get_config_file_content()
    if not conf:
        console.print(f"[yellow]Aviso:[/yellow] Arquivo de configuração não encontrado ou inválido em [dim]{config.CONFIG_PATH}[/dim]")
    else:
        console.print(f"[green]✓[/green] Arquivo de configuração carregado.")
        console.print(f"  [cyan]↳ Modelo padrão no estado:[/cyan] [bold]{config.STATE.model}[/bold]")

@app.command()
def gen(prompt: Annotated[str, typer.Argument(help="O prompt para o modelo.")]):
    """Gera uma resposta a partir de um prompt usando as configurações atuais."""
    core.run_generation(prompt)

@app.command(name="gen-auto")
def gen_auto(prompt: Annotated[str, typer.Option("--prompt", help="A descrição da automação a ser gerada.")]):
    """Gera um comando de automação para macOS para ser copiado e colado."""
    console.print(f"[bold cyan]Gerando comando de automação para o prompt:[/bold cyan] {prompt}")
    
    # 1. Encontrar o binário do Gemini
    gemini_bin = core.find_gemini_binary()
    if not gemini_bin:
        console.print("[red]Erro:[/red] Binário do Gemini não encontrado.")
        raise typer.Exit(1)

    # 2. Criar o meta-prompt
    meta_prompt = META_PROMPT_TEMPLATE.format(user_prompt=prompt)
    
    # 3. Construir o comando final para o usuário
    # Usamos shlex.quote para garantir que o prompt seja passado como uma única string segura para o shell
    import shlex
    gemini_args = [
        gemini_bin,
        "generate",
        "--model", config.STATE.model,
        "--temperature", str(config.STATE.temperature),
    ]
    gemini_cmd_part = " ".join(map(shlex.quote, gemini_args))
    
    final_command = f"echo {shlex.quote(meta_prompt)} | {gemini_cmd_part} | osascript -e -"
    
    console.print("\n[bold green]✓ Comando gerado com sucesso![/bold green]")
    console.print("\n[yellow]AVISO:[/yellow] Devido a limitações do ambiente de script, a execução direta falhou.")
    console.print("Copie e cole o seguinte comando completo no seu terminal macOS para executar a automação:")
    console.print("\n---")
    console.print(f"[bold]{final_command}[/bold]")
    console.print("---")

@app.command(name="models")
def list_models():
    """Lista os modelos disponíveis através do binário do Gemini."""
    gemini_bin = core.find_gemini_binary()
    if not gemini_bin:
        console.print("[red]Erro:[/red] Binário do Gemini não encontrado.")
        raise typer.Exit(1)
    
    console.print(f"[cyan]Executando: [bold]{gemini_bin} model list[/bold][/cyan]")
    
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

@app.command()
def others_menu():
    """Mostra o catálogo de ações, extensões e recursos."""
    others.show_others_menu()

@profile_app.command()
def apply(profile_name: str):
    """Carrega e aplica um perfil do arquivo de configuração ao estado atual."""
    console.print(f"[cyan]Tentando aplicar o perfil '[bold]{profile_name}[/bold]'...[/cyan]")
    success = config.apply_profile(profile_name)
    
    if not success:
        console.print(f"[red]Erro:[/red] Perfil '[bold]{profile_name}[/bold]' não encontrado.")
        raise typer.Exit(1)
    
    console.print("[green]✓[/green] Perfil aplicado com sucesso ao estado da sessão.")
    console.print(f"  [cyan]↳ Modelo no estado:[/cyan] [bold]{config.STATE.model}[/bold]")
    console.print(f"  [cyan]↳ Temperatura no estado:[/cyan] {config.STATE.temperature}")
    console.print(f"  [cyan]↳ System prompt no estado:[/cyan] '{config.STATE.system}'")

# --- Inicialização ---
@app.callback()
def main_callback():
    """Carrega a configuração inicial antes de executar qualquer comando."""
    config.load_and_init_state()

if __name__ == "__main__":
    app()