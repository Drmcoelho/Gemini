# Gemini

A modern Python application framework for AI integration and development.

## Overview

Gemini is a flexible and extensible framework designed to facilitate the development of AI-powered applications. It provides a clean architecture for integrating with various AI services, managing configurations, and building scalable applications.

## Features

- 🤖 AI Service Integration (Google Gemini API, OpenAI, etc.)
- 🏗️ Modular Architecture
- ⚙️ Configuration Management
- 🧪 Testing Framework
- 📝 Comprehensive Documentation
- 🐳 Docker Support
- 🚀 Easy Deployment

## Quick Start

### Prerequisites

- Python 3.8 or higher
- pip package manager

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Drmcoelho/Gemini.git
cd Gemini
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Set up configuration:
```bash
cp config/config.example.yaml config/config.yaml
# Edit config/config.yaml with your settings
```

5. Run the application:
```bash
python -m gemini
```

## Project Structure

```
gemini/
├── gemini/                 # Main application package
│   ├── __init__.py
│   ├── core/              # Core functionality
│   ├── services/          # Service integrations
│   ├── utils/             # Utility functions
│   └── cli/               # Command line interface
├── config/                # Configuration files
├── tests/                 # Test suite
├── docs/                  # Documentation
├── scripts/               # Utility scripts
├── docker/                # Docker configuration
├── requirements.txt       # Python dependencies
├── setup.py              # Package setup
├── Dockerfile            # Docker image
└── README.md             # This file
```

## Development

### Setting up Development Environment

1. Install development dependencies:
```bash
pip install -r requirements-dev.txt
```

2. Run tests:
```bash
pytest
```

3. Run linting:
```bash
flake8 gemini/
black gemini/
```

4. Run type checking:
```bash
mypy gemini/
```

## Configuration

The application uses YAML configuration files. Copy `config/config.example.yaml` to `config/config.yaml` and customize as needed.

## API Integration

### Google Gemini API

To use Google Gemini API, set your API key in the configuration:

```yaml
ai_services:
  gemini:
    api_key: "your-api-key-here"
    model: "gemini-pro"
```

### OpenAI Integration

For OpenAI integration:

```yaml
ai_services:
  openai:
    api_key: "your-openai-key"
    model: "gpt-3.5-turbo"
```

## Usage Examples

### Basic Usage

```python
from gemini import GeminiApp

app = GeminiApp()
response = app.generate_text("Hello, how are you?")
print(response)
```

### Advanced Usage

```python
from gemini.services import AIService
from gemini.core import ConfigManager

config = ConfigManager.load_config()
ai_service = AIService(config)

result = ai_service.process_request({
    "prompt": "Explain quantum computing",
    "model": "gemini-pro",
    "temperature": 0.7
})
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

Run the test suite:

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=gemini

# Run specific test file
pytest tests/test_core.py
```

## Docker

### Build and Run

```bash
# Build the image
docker build -t gemini:latest .

# Run the container
docker run -p 8000:8000 gemini:latest
```

### Docker Compose

```bash
docker-compose up -d
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.

## Support

- 📧 Email: drmatheuscoelho@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/Drmcoelho/Gemini/issues)
- 📖 Documentation: [Wiki](https://github.com/Drmcoelho/Gemini/wiki)
