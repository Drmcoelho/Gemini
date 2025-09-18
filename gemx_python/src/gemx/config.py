# Lógica para carregar e gerenciar o config.json e o estado da aplicação
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Any, Optional

# Caminho padrão para o arquivo de configuração
CONFIG_PATH = Path.home() / ".config" / "gemx" / "config.json"

@dataclass
class GemxState:
    """Mantém o estado atual das configurações da aplicação."""
    model: str = "gemini-2.5-pro"
    temperature: float = 0.2
    system: str = ""
    # Adicione outros campos conforme necessário

# Variável de estado global, inicializada com padrões
STATE = GemxState()

# Cache para o arquivo de configuração
_config_cache: Optional[Dict[str, Any]] = None

def get_config_file_content() -> Dict[str, Any]:
    """Carrega o arquivo de configuração JSON, usando um cache simples."""
    global _config_cache
    if _config_cache is not None:
        return _config_cache

    if not CONFIG_PATH.is_file():
        _config_cache = {}
        return _config_cache

    with open(CONFIG_PATH, "r") as f:
        try:
            _config_cache = json.load(f)
            return _config_cache
        except json.JSONDecodeError:
            _config_cache = {}
            return _config_cache

def load_and_init_state():
    """Carrega a configuração do arquivo e inicializa o estado global.
    
    Deve ser chamado na inicialização do CLI.
    """
    config = get_config_file_content()
    STATE.model = config.get("model", STATE.model)
    STATE.temperature = config.get("temperature", STATE.temperature)
    STATE.system = config.get("system", STATE.system)

def apply_profile(profile_name: str) -> bool:
    """Aplica um perfil ao estado global. Retorna True em sucesso, False se não encontrado."""
    config = get_config_file_content()
    profiles = config.get("profiles", {})
    
    if profile_name not in profiles:
        return False
        
    profile_settings = profiles[profile_name]
    
    # Atualiza o estado com as configurações do perfil, usando os valores atuais como fallback
    STATE.model = profile_settings.get("model", STATE.model)
    STATE.temperature = profile_settings.get("temperature", STATE.temperature)
    STATE.system = profile_settings.get("system", STATE.system)
    return True
