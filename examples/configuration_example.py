#!/usr/bin/env python3
"""
Configuration example for the Gemini framework.

This example demonstrates how to work with configuration in the Gemini framework.
"""

import json
from gemini.core.config import ConfigManager


def main():
    """Run the configuration example."""
    print("Gemini Framework - Configuration Example")
    print("=" * 45)
    
    # Initialize configuration manager
    print("\n1. Loading configuration...")
    config_manager = ConfigManager()
    
    # Display full configuration (with sensitive data hidden)
    print("\n2. Current configuration:")
    config = config_manager.get_config()
    
    # Create a safe copy for display
    safe_config = json.loads(json.dumps(config))
    for service in safe_config.get('ai_services', {}).values():
        if isinstance(service, dict) and 'api_key' in service:
            if service['api_key']:
                service['api_key'] = '***CONFIGURED***'
            else:
                service['api_key'] = '***NOT_SET***'
    
    print(json.dumps(safe_config, indent=2))
    
    # Demonstrate getting specific configuration values
    print("\n3. Getting specific configuration values...")
    
    app_name = config_manager.get('app.name')
    print(f"Application name: {app_name}")
    
    default_service = config_manager.get('ai_services.default_service')
    print(f"Default AI service: {default_service}")
    
    gemini_model = config_manager.get('ai_services.gemini.model')
    print(f"Gemini model: {gemini_model}")
    
    # Getting a non-existent key with default
    missing_value = config_manager.get('non.existent.key', 'default_value')
    print(f"Missing key with default: {missing_value}")
    
    # Demonstrate environment variable handling
    print("\n4. Environment variable information:")
    print("The following environment variables can be used to override configuration:")
    print("- GEMINI_API_KEY: Google Gemini API key")
    print("- OPENAI_API_KEY: OpenAI API key")
    print("- DEBUG: Enable debug mode (true/false)")
    print("- LOG_LEVEL: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)")
    
    print("\nExample:")
    print("export GEMINI_API_KEY='your-api-key-here'")
    print("export DEBUG=true")
    print("python -m gemini generate 'Hello, world!'")


if __name__ == "__main__":
    main()