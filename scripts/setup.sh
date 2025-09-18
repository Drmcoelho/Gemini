#!/bin/bash
# Setup script for Gemini framework development environment

set -e

echo "Setting up Gemini development environment..."

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
required_version="3.8"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "Error: Python $required_version or higher is required. Found: $python_version"
    exit 1
fi

echo "✓ Python version check passed ($python_version)"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Install development dependencies
echo "Installing development dependencies..."
pip install -r requirements-dev.txt

# Install package in development mode
echo "Installing Gemini package in development mode..."
pip install -e .

# Create config directory and copy example config
echo "Setting up configuration..."
mkdir -p config
if [ ! -f "config/config.yaml" ]; then
    cp config/config.example.yaml config/config.yaml
    echo "✓ Created config/config.yaml from example"
    echo "  Please edit config/config.yaml with your API keys"
else
    echo "✓ config/config.yaml already exists"
fi

# Create logs directory
mkdir -p logs

echo ""
echo "Setup complete! 🎉"
echo ""
echo "Next steps:"
echo "1. Activate the virtual environment: source venv/bin/activate"
echo "2. Edit config/config.yaml with your API keys"
echo "3. Run tests: pytest"
echo "4. Try the CLI: python -m gemini --help"
echo "5. Run examples: python examples/basic_usage.py"
echo ""
echo "For more information, see README.md"