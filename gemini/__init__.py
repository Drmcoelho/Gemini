"""
Gemini - A modern Python application framework for AI integration.

This package provides a comprehensive framework for building AI-powered applications
with support for various AI services, configuration management, and scalable architecture.
"""

__version__ = "0.1.0"
__author__ = "Matheus Migliolo Coelho"
__email__ = "drmatheuscoelho@gmail.com"

from .core.app import GeminiApp
from .core.config import ConfigManager
from .services.ai_service import AIService

__all__ = [
    "GeminiApp",
    "ConfigManager", 
    "AIService",
    "__version__",
]