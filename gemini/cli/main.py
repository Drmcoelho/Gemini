"""
Main CLI interface for the Gemini framework.
"""

import argparse
import json
import sys
from typing import Optional

from ..core.app import GeminiApp
from ..utils.logger import setup_logger


def create_parser() -> argparse.ArgumentParser:
    """Create the argument parser for the CLI."""
    parser = argparse.ArgumentParser(
        description="Gemini - AI Integration Framework",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  gemini generate "Hello, how are you?"
  gemini generate "Explain AI" --provider openai
  gemini health
  gemini config
        """
    )
    
    parser.add_argument(
        '--config',
        type=str,
        help='Path to configuration file'
    )
    
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose logging'
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Generate command  
    generate_parser = subparsers.add_parser('generate', help='Generate text using AI')
    generate_parser.add_argument('prompt', help='Text prompt for generation')
    generate_parser.add_argument('--provider', help='AI provider to use')
    generate_parser.add_argument('--model', help='AI model to use')
    generate_parser.add_argument('--temperature', type=float, help='Generation temperature')
    
    # Health command
    subparsers.add_parser('health', help='Check application health')
    
    # Config command
    subparsers.add_parser('config', help='Show current configuration')
    
    # Interactive command
    subparsers.add_parser('interactive', help='Start interactive mode')
    
    return parser


def cmd_generate(app: GeminiApp, args: argparse.Namespace) -> int:
    """Handle the generate command."""
    try:
        kwargs = {}
        if args.model:
            kwargs['model'] = args.model
        if args.temperature is not None:
            kwargs['temperature'] = args.temperature
            
        response = app.generate_text(args.prompt, args.provider, **kwargs)
        print(response)
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def cmd_health(app: GeminiApp, args: argparse.Namespace) -> int:
    """Handle the health command."""
    try:
        health = app.health_check()
        print(json.dumps(health, indent=2))
        return 0 if health['status'] == 'healthy' else 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def cmd_config(app: GeminiApp, args: argparse.Namespace) -> int:
    """Handle the config command."""
    try:
        config = app.config_manager.get_config()
        # Remove sensitive information before displaying
        safe_config = json.loads(json.dumps(config))
        for service in safe_config.get('ai_services', {}).values():
            if isinstance(service, dict) and 'api_key' in service:
                service['api_key'] = '***HIDDEN***'
        
        print(json.dumps(safe_config, indent=2))
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


def cmd_interactive(app: GeminiApp, args: argparse.Namespace) -> int:
    """Handle the interactive command."""
    print("Gemini Interactive Mode")
    print("Type 'quit' or 'exit' to leave, 'help' for commands")
    print()
    
    while True:
        try:
            prompt = input("gemini> ").strip()
            
            if not prompt:
                continue
                
            if prompt.lower() in ['quit', 'exit']:
                print("Goodbye!")
                break
                
            if prompt.lower() == 'help':
                print("Available commands:")
                print("  <text>        - Generate text")
                print("  health        - Check health")
                print("  config        - Show config")
                print("  quit/exit     - Exit interactive mode")
                continue
                
            if prompt.lower() == 'health':
                health = app.health_check()
                print(json.dumps(health, indent=2))
                continue
                
            if prompt.lower() == 'config':
                cmd_config(app, args)
                continue
            
            # Treat as text generation prompt
            response = app.generate_text(prompt)
            print(response)
            print()
            
        except KeyboardInterrupt:
            print("\nGoodbye!")
            break
        except Exception as e:
            print(f"Error: {e}")
    
    return 0


def main() -> int:
    """Main CLI entry point."""
    parser = create_parser()
    args = parser.parse_args()
    
    # Set up logging
    log_level = 'DEBUG' if args.verbose else 'INFO'
    logger = setup_logger(__name__, log_level)
    
    try:
        # Initialize the application
        app = GeminiApp(config_path=args.config)
        
        # Handle commands
        if args.command == 'generate':
            return cmd_generate(app, args)
        elif args.command == 'health':
            return cmd_health(app, args)
        elif args.command == 'config':
            return cmd_config(app, args)
        elif args.command == 'interactive':
            return cmd_interactive(app, args)
        else:
            # No command specified, show help
            parser.print_help()
            return 0
            
    except Exception as e:
        logger.error(f"Application error: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1
    finally:
        # Cleanup
        if 'app' in locals():
            app.shutdown()


if __name__ == '__main__':
    sys.exit(main())