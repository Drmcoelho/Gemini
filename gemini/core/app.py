"""
Main application class for Gemini framework.
"""

import logging
from typing import Dict, Any, Optional
from .config import ConfigManager
from ..services.ai_service import AIService
from ..utils.logger import setup_logger


class GeminiApp:
    """
    Main application class that coordinates all Gemini components.
    
    This class serves as the primary interface for the Gemini framework,
    managing configuration, services, and providing high-level methods
    for common operations.
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the Gemini application.
        
        Args:
            config_path: Path to configuration file. If None, uses default.
        """
        self.logger = setup_logger(__name__)
        self.logger.info("Initializing Gemini application")
        
        # Load configuration
        self.config_manager = ConfigManager(config_path)
        self.config = self.config_manager.get_config()
        
        # Initialize services
        self.ai_service = AIService(self.config.get('ai_services', {}))
        
        self.logger.info("Gemini application initialized successfully")
    
    def generate_text(self, prompt: str, model: Optional[str] = None, **kwargs) -> str:
        """
        Generate text using the configured AI service.
        
        Args:
            prompt: The input prompt for text generation
            model: AI model to use (if not specified, uses default)
            **kwargs: Additional parameters for the AI service
            
        Returns:
            Generated text response
        """
        try:
            return self.ai_service.generate_text(prompt, model, **kwargs)
        except Exception as e:
            self.logger.error(f"Error generating text: {e}")
            raise
    
    def process_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process a structured request through the AI service.
        
        Args:
            request: Dictionary containing request parameters
            
        Returns:
            Dictionary containing the response
        """
        try:
            return self.ai_service.process_request(request)
        except Exception as e:
            self.logger.error(f"Error processing request: {e}")
            raise
    
    def health_check(self) -> Dict[str, Any]:
        """
        Perform a health check of the application and its services.
        
        Returns:
            Dictionary containing health status information
        """
        health_status = {
            "status": "healthy",
            "version": self.config.get("version", "unknown"),
            "services": {}
        }
        
        # Check AI service health
        try:
            ai_health = self.ai_service.health_check()
            health_status["services"]["ai_service"] = ai_health
        except Exception as e:
            health_status["services"]["ai_service"] = {
                "status": "unhealthy",
                "error": str(e)
            }
            health_status["status"] = "degraded"
        
        return health_status
    
    def shutdown(self):
        """Gracefully shutdown the application."""
        self.logger.info("Shutting down Gemini application")
        # Perform any cleanup operations here
        self.logger.info("Gemini application shutdown complete")