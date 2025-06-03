# Devstral Model with OpenHands Web Deployment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![OpenHands](https://img.shields.io/badge/OpenHands-Compatible-green.svg)](https://docs.all-hands.dev/)

A comprehensive repository for deploying the Devstral model with OpenHands for web access on a server, eliminating the need for LM Studio on the client side.

## 🚀 Quick Start

### Automated Setup (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd devstral-openhands-deployment

# Run the interactive setup script
./scripts/setup.sh

# Test your deployment
./scripts/test-deployment.sh
```

### One-Line Deployment

```bash
# Quick start with Ollama (recommended for beginners)
cp examples/quick-start-ollama.yml docker-compose.yml && docker-compose up -d

# Production setup with Text Generation WebUI
cp examples/production-textgen.yml docker-compose.yml && docker-compose up -d

# High-performance setup with llama.cpp
cp examples/high-performance-llamacpp.yml docker-compose.yml && docker-compose up -d
```

## 📋 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [🎯 Core Concept](#-core-concept)
- [📦 Repository Structure](#-repository-structure)
- [⚙️ Deployment Options](#️-deployment-options)
- [🔧 Configuration](#-configuration)
- [📊 Monitoring & Testing](#-monitoring--testing)
- [🐛 Troubleshooting](#-troubleshooting)
- [🏆 Advantages](#-advantages)
- [📚 Documentation](#-documentation)
- [🤝 Contributing](#-contributing)

## 🎯 Core Concept

This deployment replaces LM Studio with a server-side solution that:

1. **Serves the Devstral GGUF model** via HTTP API using your choice of:
   - Ollama (user-friendly, web UI included)
   - Text Generation WebUI (feature-rich, production-ready)
   - llama.cpp server (high-performance, minimal overhead)

2. **Runs OpenHands** in a Docker container configured to connect to your model API

3. **Provides web access** to the OpenHands interface from any browser

4. **Enables centralized control** with optional monitoring and scaling

## 📦 Repository Structure

```
devstral-openhands-deployment/
├── README.md                    # This file
├── LICENSE                      # MIT License
├── .gitignore                  # Git ignore rules
├── ollama-setup/               # Ollama deployment files
│   ├── README.md
│   ├── docker-compose.yml
│   ├── Modelfile
│   └── test-api.sh
├── text-generation-webui/      # Text Generation WebUI setup
│   ├── README.md
│   ├── docker-compose.yml
│   ├── settings.yaml
│   └── test-api.sh
├── llamacpp-server/            # llama.cpp server setup
│   ├── README.md
│   ├── docker-compose.yml
│   ├── docker-compose.gpu.yml
│   ├── test-api.sh
│   └── start-server.sh
├── examples/                   # Complete deployment examples
│   ├── README.md
│   ├── quick-start-ollama.yml
│   ├── production-textgen.yml
│   └── high-performance-llamacpp.yml
├── docs/                       # Documentation
│   ├── deployment-guide.md
│   └── troubleshooting.md
└── scripts/                    # Utility scripts
    ├── setup.sh               # Interactive setup script
    └── test-deployment.sh     # Deployment testing script
```

## ⚙️ Deployment Options

### 🟢 Option 1: Ollama (Recommended for Beginners)

**Best for**: First-time users, development, quick prototyping

**Features**:
- User-friendly web interface
- Easy model management
- Built-in model library
- Simple configuration

**Quick Start**:
```bash
cd ollama-setup/
docker-compose up -d
```

### 🟡 Option 2: Text Generation WebUI (Production Ready)

**Best for**: Production environments, advanced features, monitoring

**Features**:
- Comprehensive web interface
- Advanced model parameters
- Chat templates and personas
- API compatibility
- Monitoring and logging

**Quick Start**:
```bash
cd text-generation-webui/
docker-compose up -d
```

### 🔴 Option 3: llama.cpp Server (High Performance)

**Best for**: Maximum performance, minimal overhead, GPU acceleration

**Features**:
- Optimized inference engine
- GPU acceleration support
- Minimal resource usage
- OpenAI-compatible API

**Quick Start**:
```bash
cd llamacpp-server/
docker-compose up -d
```

## 🔧 Configuration

### Prerequisites

**System Requirements**:
- **Minimum**: 8GB RAM, 4 CPU cores, 20GB disk space
- **Recommended**: 16GB+ RAM, 8+ CPU cores, 50GB+ disk space
- **GPU**: NVIDIA GPU with 8GB+ VRAM (optional, for acceleration)

**Software**:
- Docker 20.10+
- Docker Compose 2.0+
- Git (for cloning)

### Environment Variables

Create a `.env` file to customize your deployment:

```bash
# Model Configuration
MODEL_FILE=devstral-model.gguf
MODEL_NAME=devstral
CONTEXT_SIZE=4096

# Performance Settings
THREADS=8
BATCH_SIZE=512
GPU_LAYERS=0  # Set to 35+ for GPU acceleration

# Port Configuration
OPENHANDS_PORT=3000
MODEL_SERVER_PORT=8080

# Paths
WORKSPACE_PATH=./workspace
MODELS_PATH=./models
```

### Custom Deployment

```bash
# Use environment variables
MODEL_FILE=my-model.gguf GPU_LAYERS=35 docker-compose up -d

# Use specific example
cp examples/high-performance-llamacpp.yml docker-compose.yml
docker-compose up -d
```

## 📊 Monitoring & Testing

### Health Checks

All deployments include built-in health checks:

```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs -f

# Test API endpoints
./scripts/test-deployment.sh
```

### Performance Monitoring

For production deployments with monitoring:

```bash
# Start with monitoring stack
docker-compose --profile monitoring up -d

# Access monitoring interfaces
# Grafana: http://localhost:3001
# Prometheus: http://localhost:9090
```

### Testing Your Deployment

```bash
# Comprehensive deployment test
./scripts/test-deployment.sh

# Quick API test (varies by deployment)
curl http://localhost:8080/v1/models  # llama.cpp
curl http://localhost:11434/api/tags  # Ollama
curl http://localhost:5000/api/v1/model  # Text Generation WebUI
```

## 🐛 Troubleshooting

### Common Issues

1. **Docker Image Pull Failures**:
   ```bash
   # Use correct OpenHands image
   docker pull docker.all-hands.dev/all-hands-ai/openhands:0.40
   ```

2. **Model Loading Issues**:
   ```bash
   # Check model file exists
   ls -la models/
   
   # Verify model in container
   docker exec -it ollama ollama list
   ```

3. **API Connection Issues**:
   ```bash
   # Test network connectivity
   docker exec -it openhands curl http://ollama:11434/api/tags
   ```

4. **Port Conflicts**:
   ```bash
   # Change ports in docker-compose.yml
   ports:
     - "3001:3000"  # Change from 3000:3000
   ```

For detailed troubleshooting, see [docs/troubleshooting.md](docs/troubleshooting.md).

## 🏆 Advantages

### Over Local LM Studio Setup

- **🌐 Web Access**: Access from any browser, any device
- **🔄 Centralized Control**: Manage from a single server
- **📈 Scalability**: Easy to scale resources or add instances
- **🔒 Security**: Centralized security management
- **👥 Multi-User**: Support multiple concurrent users
- **📊 Monitoring**: Built-in monitoring and logging
- **🚀 Performance**: Dedicated server resources

### Deployment Benefits

- **🐳 Containerized**: Consistent deployment across environments
- **⚡ Quick Setup**: Automated setup scripts and examples
- **🔧 Configurable**: Multiple deployment options and configurations
- **🧪 Testable**: Comprehensive testing scripts
- **📖 Documented**: Extensive documentation and examples

## 📚 Documentation

- **[Deployment Guide](docs/deployment-guide.md)**: Step-by-step deployment instructions
- **[Troubleshooting Guide](docs/troubleshooting.md)**: Common issues and solutions
- **[Examples](examples/README.md)**: Ready-to-use deployment examples
- **[Ollama Setup](ollama-setup/README.md)**: Ollama-specific instructions
- **[Text Generation WebUI](text-generation-webui/README.md)**: WebUI setup guide
- **[llama.cpp Server](llamacpp-server/README.md)**: High-performance setup

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

```bash
# Clone the repository
git clone <repository-url>
cd devstral-openhands-deployment

# Test your changes
./scripts/test-deployment.sh

# Submit a pull request
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [OpenHands](https://github.com/All-Hands-AI/OpenHands) - AI agent framework
- [Ollama](https://ollama.ai/) - Local LLM server
- [Text Generation WebUI](https://github.com/oobabooga/text-generation-webui) - Web interface for LLMs
- [llama.cpp](https://github.com/ggerganov/llama.cpp) - High-performance LLM inference

## 🆘 Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Documentation**: [docs/](docs/)

---

**Ready to deploy?** Start with `./scripts/setup.sh` for an interactive setup experience!