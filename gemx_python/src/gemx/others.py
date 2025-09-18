# Lógica para o menu 'others'
import json
import subprocess
from pathlib import Path
from typing import Dict, Any, List

from rich.console import Console
from rich.prompt import Prompt
from rich.table import Table

from . import config # Para acessar o estado (ex: para templates)

# O path para others.json pode ser configurável no futuro
OTHERS_PATH = Path(__file__).parent.parent.parent.parent / "others.json"

console = Console()

def _run_shell_command(command: str):
    """Helper para executar um comando shell e imprimir a saída."""
    console.print(f"[cyan]Executando comando shell:[/cyan] [bold]{command}[/bold]")
    try:
        subprocess.run(command, shell=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        console.print(f"[red]Erro ao executar o comando:[/red] {e}")

def _execute_action(action: Dict[str, Any]):
    """Executa uma ação específica do catálogo."""
    action_type = action.get("type")
    
    # TODO: Portar a lógica de execução de `gemx.sh` para cá
    if action_type == "prompt":
        # No futuro, isso chamaria a função `gen`
        console.print(f"[bold]Prompt:[/bold] {action.get('prompt')}")
        console.print("[yellow]Execução de prompt ainda não implementada.[/yellow]")
    elif action_type == "shell":
        _run_shell_command(action.get("command", ""))
    elif action_type == "automation":
        console.print(f"[yellow]Execução de automação ('{action.get('file')}') ainda não implementada.[/yellow]")
    elif action_type == "template":
        console.print(f"[yellow]Execução de template ('{action.get('template_key')}') ainda não implementada.[/yellow]")
    else:
        console.print(f"[red]Tipo de ação desconhecido:[/red] {action_type}")

def _show_actions_menu(actions: List[Dict[str, Any]]):
    """Mostra o menu para a categoria 'Ações'."""
    while True:
        table = Table(title="[bold]Ações[/bold]", show_header=True, header_style="bold magenta")
        table.add_column("#", style="dim")
        table.add_column("Label")
        table.add_column("Tipo")
        
        for i, item in enumerate(actions):
            table.add_row(str(i + 1), item.get("label", "N/A"), item.get("type", "N/A"))
        
        console.print(table)
        console.print("[bold]Digite o número da ação para executar, ou 'v' para voltar.[/bold]")
        
        choice = Prompt.ask("> ")
        if choice.lower() == 'v':
            break
        
        try:
            index = int(choice) - 1
            if 0 <= index < len(actions):
                _execute_action(actions[index])
            else:
                console.print("[red]Número inválido.[/red]")
        except ValueError:
            console.print("[red]Entrada inválida.[/red]")

# Funções de placeholder para outros menus
def _show_extensions_menu(extensions: List[Dict[str, Any]]):
    console.print("[yellow]Menu de Extensões ainda não implementado.[/yellow]")

def _show_plugins_menu(plugins: List[Dict[str, Any]]):
    console.print("[yellow]Menu de Plugins ainda não implementado.[/yellow]")

def _show_resources_menu(resources: List[Dict[str, Any]]):
    console.print("[yellow]Menu de Recursos ainda não implementado.[/yellow]")


def show_others_menu():
    """Ponto de entrada principal para a funcionalidade 'others'."""
    others_data = load_others_file()
    if not others_data:
        return

    while True:
        console.print("\n[bold cyan]Catálogo 'Others'[/bold cyan]")
        metadata = others_data.get("metadata", {})
        console.print(f"Versão: {metadata.get('version', 'N/A')}")
        
        menu_options = {
            "1": ("Extensões", others_data.get("extensions", [])),
            "2": ("Plugins", others_data.get("plugins", [])),
            "3": ("Ações", others_data.get("actions", [])),
            "4": ("Recursos", others_data.get("resources", [])),
        }
        
        console.print("\n[bold]Selecione uma categoria:[/bold]")
        for key, (name, items) in menu_options.items():
            console.print(f"  [bold]{key}[/bold]) {name} ({len(items)} itens)")
        console.print("  [bold]5[/bold]) Sair")

        choice = Prompt.ask("\n> ", choices=list(menu_options.keys()) + ["5"], default="5")

        if choice == "1":
            _show_extensions_menu(menu_options[choice][1])
        elif choice == "2":
            _show_plugins_menu(menu_options[choice][1])
        elif choice == "3":
            _show_actions_menu(menu_options[choice][1])
        elif choice == "4":
            _show_resources_menu(menu_options[choice][1])
        elif choice == "5":
            break

def load_others_file() -> Dict[str, Any]:
    """Carrega e parseia o arquivo others.json."""
    if not OTHERS_PATH.is_file():
        console.print(f"[red]Erro:[/red] Arquivo '[bold]{OTHERS_PATH}[/bold]' não encontrado.")
        return {}
    
    with open(OTHERS_PATH, "r") as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            console.print(f"[red]Erro:[/red] Arquivo '[bold]{OTHERS_PATH}[/bold]' é um JSON inválido.")
            return {}