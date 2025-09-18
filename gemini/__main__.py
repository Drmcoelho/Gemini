"""
Main entry point for the Gemini application.
Allows running the application as a module: python -m gemini
"""

import sys
from .cli.main import main

if __name__ == "__main__":
    sys.exit(main())