# Lógica para carregar e gerenciar o config.json do gemx
import json
from pathlib import Path
from typing import Dict, Any, Optional

# Caminho padrão para o arquivo de configuração
CONFIG_PATH = Path.home() / ".config" / "gemx" / "config.json"

# Um cache simples para evitar leituras repetidas do disco
_config_cache: Optional[Dict[str, Any]] = None

def get_config() -> Dict[str, Any]:
    """Carrega o arquivo de configuração JSON e o retorna como um dicionário.

    Faz cache do resultado para evitar I/O desnecessário em chamadas futuras.
    """
    global _config_cache
    if _config_cache is not None:
        return _config_cache

    if not CONFIG_PATH.is_file():
        # No futuro, podemos chamar uma função para criar um config padrão
        return {}

    with open(CONFIG_PATH, "r") as f:
        try:
            _config_cache = json.load(f)
            return _config_cache
        except json.JSONDecodeError:
            # Retorna um dict vazio se o JSON for inválido
            return {}

def get_default_model() -> str:
    """Retorna o modelo padrão do arquivo de configuração."""
    config = get_config()
    # Usa 'gemini-2.5-pro' como fallback, assim como o script shell
    return config.get("model", "gemini-2.5-pro")
