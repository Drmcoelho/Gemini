#!/usr/bin/env python3
"""
Basic usage example for the Gemini framework.

This example demonstrates how to use the Gemini framework for basic AI text generation.
"""

from gemini import GeminiApp


def main():
    """Run the basic usage example."""
    print("Gemini Framework - Basic Usage Example")
    print("=" * 40)
    
    # Initialize the Gemini application
    print("\n1. Initializing Gemini application...")
    app = GeminiApp()
    
    # Check application health
    print("\n2. Checking application health...")
    health = app.health_check()
    print(f"Application status: {health['status']}")
    
    # Generate text (this will use simulated responses since no real API keys are configured)
    print("\n3. Generating text...")
    try:
        prompt = "Explain what artificial intelligence is in simple terms."
        response = app.generate_text(prompt)
        print(f"Prompt: {prompt}")
        print(f"Response: {response}")
    except Exception as e:
        print(f"Error generating text: {e}")
        print("Note: This is expected if no AI service is properly configured.")
    
    # Process a structured request
    print("\n4. Processing structured request...")
    try:
        request = {
            "prompt": "Write a haiku about technology",
            "temperature": 0.8
        }
        response = app.process_request(request)
        print(f"Request: {request}")
        print(f"Response: {response}")
    except Exception as e:
        print(f"Error processing request: {e}")
        print("Note: This is expected if no AI service is properly configured.")
    
    # Shutdown the application
    print("\n5. Shutting down application...")
    app.shutdown()
    print("Done!")


if __name__ == "__main__":
    main()