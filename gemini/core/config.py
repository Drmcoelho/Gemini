"""
Configuration management for the Gemini framework.
"""

import os
import yaml
from typing import Dict, Any, Optional
from pathlib import Path


class ConfigManager:
    """
    Manages configuration loading and access for the Gemini application.
    
    Supports YAML configuration files with environment variable overrides.
    """
    
    DEFAULT_CONFIG_PATH = "config/config.yaml"
    DEFAULT_CONFIG = {
        "app": {
            "name": "Gemini",
            "version": "0.1.0",
            "debug": False
        },
        "ai_services": {
            "default_service": "gemini",
            "gemini": {
                "enabled": True,
                "model": "gemini-pro",
                "temperature": 0.7,
                "max_tokens": 1000
            },
            "openai": {
                "enabled": False,
                "model": "gpt-3.5-turbo",
                "temperature": 0.7,
                "max_tokens": 1000
            }
        },
        "logging": {
            "level": "INFO",
            "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        }
    }
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the configuration manager.
        
        Args:
            config_path: Path to the configuration file
        """
        self.config_path = config_path or self.DEFAULT_CONFIG_PATH
        self._config = None
        self._load_config()
    
    def _load_config(self):
        """Load configuration from file and apply environment overrides."""
        # Start with default configuration
        self._config = self.DEFAULT_CONFIG.copy()
        
        # Load from file if it exists
        config_file = Path(self.config_path)
        if config_file.exists():
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    file_config = yaml.safe_load(f)
                    if file_config:
                        self._merge_configs(self._config, file_config)
            except Exception as e:
                print(f"Warning: Could not load config file {self.config_path}: {e}")
        
        # Apply environment variable overrides
        self._apply_env_overrides()
    
    def _merge_configs(self, base: Dict[str, Any], override: Dict[str, Any]):
        """
        Recursively merge configuration dictionaries.
        
        Args:
            base: Base configuration dictionary to merge into
            override: Configuration dictionary to merge from
        """
        for key, value in override.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self._merge_configs(base[key], value)
            else:
                base[key] = value
    
    def _apply_env_overrides(self):
        """Apply environment variable overrides to configuration."""
        # API Keys from environment
        gemini_key = os.getenv('GEMINI_API_KEY')
        if gemini_key:
            self._config['ai_services']['gemini']['api_key'] = gemini_key
        
        openai_key = os.getenv('OPENAI_API_KEY')
        if openai_key:
            self._config['ai_services']['openai']['api_key'] = openai_key
        
        # Debug mode
        debug = os.getenv('DEBUG', '').lower() in ('true', '1', 'yes', 'on')
        if debug:
            self._config['app']['debug'] = True
        
        # Logging level
        log_level = os.getenv('LOG_LEVEL')
        if log_level:
            self._config['logging']['level'] = log_level.upper()
    
    def get_config(self) -> Dict[str, Any]:
        """
        Get the complete configuration dictionary.
        
        Returns:
            The merged configuration dictionary
        """
        return self._config.copy()
    
    def get(self, key: str, default: Any = None) -> Any:
        """
        Get a configuration value by key path.
        
        Args:
            key: Dot-separated key path (e.g., 'ai_services.gemini.api_key')
            default: Default value if key is not found
            
        Returns:
            Configuration value or default
        """
        keys = key.split('.')
        value = self._config
        
        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        
        return value
    
    def reload(self):
        """Reload configuration from file."""
        self._load_config()