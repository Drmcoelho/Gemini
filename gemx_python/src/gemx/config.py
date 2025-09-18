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
    plugins: Dict[str, bool] = field(default_factory=dict)

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

def _write_config_file(config_data: Dict[str, Any]):
    """Escreve os dados de configuração de volta para o arquivo."""
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(CONFIG_PATH, "w") as f:
        json.dump(config_data, f, indent=2)

def load_and_init_state():
    """Carrega a configuração do arquivo e inicializa o estado global.
    
    Deve ser chamado na inicialização do CLI.
    """
    config_data = get_config_file_content()
    STATE.model = config_data.get("model", STATE.model)
    STATE.temperature = config_data.get("temperature", STATE.temperature)
    STATE.system = config_data.get("system", STATE.system)
    STATE.plugins = config_data.get("plugins", STATE.plugins)

def apply_profile(profile_name: str) -> bool:
    """Aplica um perfil ao estado global. Retorna True em sucesso, False se não encontrado."""
    config_data = get_config_file_content()
    profiles = config_data.get("profiles", {})
    
    if profile_name not in profiles:
        return False
        
    profile_settings = profiles[profile_name]
    
    # Atualiza o estado com as configurações do perfil, usando os valores atuais como fallback
    STATE.model = profile_settings.get("model", STATE.model)
    STATE.temperature = profile_settings.get("temperature", STATE.temperature)
    STATE.system = profile_settings.get("system", STATE.system)
    STATE.plugins = profile_settings.get("plugins", STATE.plugins)
    return True

def update_config_value(key_path: str, value: Any):
    """Atualiza um valor no arquivo de configuração e no estado global.
    
    key_path pode ser aninhado, ex: "plugins.web_fetch".
    """
    config_data = get_config_file_content()
    
    # Navega até o local da chave
    parts = key_path.split(".")
    current_level = config_data
    for i, part in enumerate(parts):
        if i == len(parts) - 1: # Última parte, define o valor
            current_level[part] = value
        else: # Não é a última parte, navega mais fundo
            if part not in current_level or not isinstance(current_level[part], dict):
                current_level[part] = {}
            current_level = current_level[part]
            
    _write_config_file(config_data)
    
    # Atualiza o estado global se a chave for relevante
    load_and_init_state() # Recarrega o estado para garantir consistência
