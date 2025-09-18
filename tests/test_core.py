"""Tests for core functionality."""

import pytest
import tempfile
import os
from pathlib import Path

from gemini.core.config import ConfigManager
from gemini.core.app import GeminiApp


class TestConfigManager:
    """Test the ConfigManager class."""
    
    def test_default_config(self):
        """Test that default configuration is loaded correctly."""
        # Use a non-existent path to ensure default config is used
        config_manager = ConfigManager("/non/existent/path.yaml")
        config = config_manager.get_config()
        
        assert "app" in config
        assert "ai_services" in config
        assert config["app"]["name"] == "Gemini"
    
    def test_get_nested_config(self):
        """Test getting nested configuration values."""
        config_manager = ConfigManager("/non/existent/path.yaml")
        
        # Test existing key
        app_name = config_manager.get("app.name")
        assert app_name == "Gemini"
        
        # Test non-existing key with default
        missing_value = config_manager.get("missing.key", "default")
        assert missing_value == "default"
    
    def test_env_override(self):
        """Test environment variable overrides."""
        # Set environment variable
        os.environ["GEMINI_API_KEY"] = "test-key"
        
        try:
            config_manager = ConfigManager("/non/existent/path.yaml")
            api_key = config_manager.get("ai_services.gemini.api_key")
            assert api_key == "test-key"
        finally:
            # Clean up
            del os.environ["GEMINI_API_KEY"]


class TestGeminiApp:
    """Test the GeminiApp class."""
    
    def test_app_initialization(self):
        """Test that the app initializes correctly."""
        app = GeminiApp()
        
        assert app.config_manager is not None
        assert app.config is not None
        assert app.ai_service is not None
    
    def test_health_check(self):
        """Test the health check functionality."""
        app = GeminiApp()
        health = app.health_check()
        
        assert "status" in health
        assert "version" in health
        assert "services" in health
        assert isinstance(health["services"], dict)
    
    def test_shutdown(self):
        """Test graceful shutdown."""
        app = GeminiApp()
        # Should not raise any exceptions
        app.shutdown()