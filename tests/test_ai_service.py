"""Tests for AI service functionality."""

import pytest
from gemini.services.ai_service import AIService, GeminiProvider, OpenAIProvider


class TestAIService:
    """Test the AIService class."""
    
    def test_initialization_no_providers(self):
        """Test initialization with no enabled providers."""
        config = {
            "default_service": "gemini",
            "gemini": {"enabled": False},
            "openai": {"enabled": False}
        }
        
        ai_service = AIService(config)
        assert len(ai_service.providers) == 0
    
    def test_initialization_with_providers(self):
        """Test initialization with enabled providers."""
        config = {
            "default_service": "gemini",
            "gemini": {
                "enabled": True,
                "api_key": "test-key",
                "model": "gemini-pro"
            }
        }
        
        ai_service = AIService(config)
        assert "gemini" in ai_service.providers
        assert isinstance(ai_service.providers["gemini"], GeminiProvider)
    
    def test_generate_text_no_provider(self):
        """Test text generation with no available providers."""
        config = {"default_service": "gemini"}
        ai_service = AIService(config)
        
        with pytest.raises(ValueError):
            ai_service.generate_text("test prompt")
    
    def test_health_check(self):
        """Test health check functionality."""
        config = {
            "default_service": "gemini",
            "gemini": {
                "enabled": True,
                "api_key": "test-key"
            }
        }
        
        ai_service = AIService(config)
        health = ai_service.health_check()
        
        assert "status" in health
        assert "providers" in health
        assert "default_provider" in health


class TestGeminiProvider:
    """Test the GeminiProvider class."""
    
    def test_generate_text_no_api_key(self):
        """Test text generation without API key."""
        config = {"model": "gemini-pro"}
        provider = GeminiProvider(config)
        
        with pytest.raises(ValueError):
            provider.generate_text("test prompt")
    
    def test_generate_text_with_api_key(self):
        """Test text generation with API key."""
        config = {
            "api_key": "test-key",
            "model": "gemini-pro"
        }
        provider = GeminiProvider(config)
        
        # Should return simulated response
        response = provider.generate_text("test prompt")
        assert "test prompt" in response
        assert "Gemini Response" in response
    
    def test_health_check(self):
        """Test health check."""
        config = {
            "api_key": "test-key",
            "model": "gemini-pro"
        }
        provider = GeminiProvider(config)
        
        health = provider.health_check()
        assert health["status"] == "healthy"
        assert health["provider"] == "Gemini"
        assert health["api_key_configured"] is True


class TestOpenAIProvider:
    """Test the OpenAIProvider class."""
    
    def test_generate_text_no_api_key(self):
        """Test text generation without API key."""
        config = {"model": "gpt-3.5-turbo"}
        provider = OpenAIProvider(config)
        
        with pytest.raises(ValueError):
            provider.generate_text("test prompt")
    
    def test_generate_text_with_api_key(self):
        """Test text generation with API key."""
        config = {
            "api_key": "test-key",
            "model": "gpt-3.5-turbo"
        }
        provider = OpenAIProvider(config)
        
        # Should return simulated response
        response = provider.generate_text("test prompt")
        assert "test prompt" in response
        assert "OpenAI Response" in response