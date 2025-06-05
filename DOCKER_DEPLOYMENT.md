# Docker Deployment Guide

This guide explains how to use the Dockerfile to deploy the complete Devstral OpenHands application in a containerized environment.

## 🐳 Overview

The Dockerfile creates a comprehensive deployment container that:

- Sets up all necessary dependencies (Docker, Docker Compose, etc.)
- Manages the complete application stack using docker-compose
- Provides multiple deployment options (Ollama, Text Generation WebUI, llama.cpp)
- Handles automatic service orchestration and health checks
- Exposes web interfaces on configurable ports

## 🚀 Quick Start

### Method 1: Using the Build Script (Recommended)

```bash
# Simple deployment with Ollama
./build-and-run.sh

# Deploy with Text Generation WebUI
./build-and-run.sh -t textgen

# Deploy with llama.cpp and GPU acceleration
./build-and-run.sh -t llamacpp -g

# Specify custom model file
./build-and-run.sh -m /path/to/your/model.gguf

# Custom ports
./build-and-run.sh -p 3000 -s 8080
```

### Method 2: Using Docker Compose

```bash
# Basic deployment
docker-compose -f docker-compose.standalone.yml up -d

# With custom configuration
DEPLOYMENT_TYPE=textgen MODEL_FILE=my-model.gguf docker-compose -f docker-compose.standalone.yml up -d
```

### Method 3: Direct Docker Build and Run

```bash
# Build the image
docker build -t devstral-openhands:latest .

# Run with default settings
docker run -d \
  --privileged \
  -p 12000:12000 \
  -p 12001:12001 \
  -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ./models:/app/models \
  -v ./workspace:/app/workspace \
  devstral-openhands:latest

# Run with custom configuration
docker run -d \
  --privileged \
  -p 3000:12000 \
  -p 8080:12001 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ./models:/app/models \
  -v ./workspace:/app/workspace \
  -e DEPLOYMENT_TYPE=textgen \
  -e MODEL_FILE=my-custom-model.gguf \
  -e GPU_ENABLED=true \
  devstral-openhands:latest
```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DEPLOYMENT_TYPE` | `ollama` | Deployment type: `ollama`, `textgen`, or `llamacpp` |
| `MODEL_FILE` | `devstral-model.gguf` | Name of the GGUF model file |
| `MODEL_NAME` | `devstral` | Name to use for the model |
| `CONTEXT_SIZE` | `4096` | Context size for the model |
| `THREADS` | `8` | Number of CPU threads to use |
| `BATCH_SIZE` | `512` | Batch size for processing |
| `GPU_LAYERS` | `0` | Number of layers to offload to GPU |
| `GPU_ENABLED` | `false` | Enable GPU acceleration |
| `OPENHANDS_PORT` | `12000` | Port for OpenHands web interface |
| `MODEL_SERVER_PORT` | `12001` | Port for model API server |
| `WEBUI_PORT` | `8080` | Port for web UI |
| `API_PORT` | `5000` | Additional API port |

### Volume Mounts

| Host Path | Container Path | Description |
|-----------|----------------|-------------|
| `./models` | `/app/models` | Directory containing GGUF model files |
| `./workspace` | `/app/workspace` | OpenHands workspace directory |
| `./logs` | `/app/logs` | Application logs |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket (required for DinD) |

## 🔧 Deployment Types

### 1. Ollama (Default)
- **Best for**: Beginners, quick setup
- **Features**: User-friendly web UI, easy model management
- **Access**: 
  - OpenHands: `http://localhost:12000`
  - Ollama Web UI: `http://localhost:8080`
  - API: `http://localhost:12001`

### 2. Text Generation WebUI
- **Best for**: Production environments, advanced features
- **Features**: Comprehensive interface, monitoring, chat templates
- **Access**:
  - OpenHands: `http://localhost:12000`
  - WebUI: `http://localhost:8080`
  - API: `http://localhost:5000`

### 3. llama.cpp Server
- **Best for**: High performance, minimal overhead
- **Features**: Optimized inference, GPU acceleration
- **Access**:
  - OpenHands: `http://localhost:12000`
  - API: `http://localhost:12001`

## 📋 Prerequisites

### System Requirements
- **Minimum**: 8GB RAM, 4 CPU cores, 20GB disk space
- **Recommended**: 16GB+ RAM, 8+ CPU cores, 50GB+ disk space
- **GPU**: NVIDIA GPU with 8GB+ VRAM (optional, for acceleration)

### Software Requirements
- Docker 20.10+
- Docker Compose 2.0+
- Git (for cloning the repository)

### Model Requirements
- Devstral model in GGUF format
- Place model file in the `models/` directory or mount it as a volume

## 🛠️ Usage Examples

### Example 1: Development Setup
```bash
# Build and run for development
./build-and-run.sh -t ollama -p 3000 -s 8080

# Access services
# OpenHands: http://localhost:3000
# Ollama UI: http://localhost:8080
```

### Example 2: Production Setup
```bash
# Production deployment with Text Generation WebUI
./build-and-run.sh -t textgen -m /path/to/production-model.gguf

# Access services
# OpenHands: http://localhost:12000
# WebUI: http://localhost:8080
```

### Example 3: High-Performance Setup
```bash
# GPU-accelerated deployment
./build-and-run.sh -t llamacpp -g -m /path/to/large-model.gguf

# Access services
# OpenHands: http://localhost:12000
# API: http://localhost:12001
```

### Example 4: Custom Configuration
```bash
# Custom environment variables
docker run -d \
  --privileged \
  --name devstral-custom \
  -p 3000:12000 \
  -p 8080:12001 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /path/to/models:/app/models \
  -v /path/to/workspace:/app/workspace \
  -e DEPLOYMENT_TYPE=textgen \
  -e MODEL_FILE=custom-model.gguf \
  -e CONTEXT_SIZE=8192 \
  -e THREADS=16 \
  -e GPU_ENABLED=true \
  -e GPU_LAYERS=35 \
  devstral-openhands:latest
```

## 📊 Monitoring and Management

### View Logs
```bash
# Using docker-compose
docker-compose -f docker-compose.standalone.yml logs -f

# Using docker directly
docker logs -f devstral-openhands-deployment

# View specific service logs
docker exec devstral-openhands-deployment docker-compose logs ollama
```

### Check Status
```bash
# Service status
docker-compose -f docker-compose.standalone.yml ps

# Container status
docker ps | grep devstral

# Health check
curl http://localhost:12000/health
```

### Management Commands
```bash
# Stop deployment
docker-compose -f docker-compose.standalone.yml down

# Restart deployment
docker-compose -f docker-compose.standalone.yml restart

# Update deployment
docker-compose -f docker-compose.standalone.yml pull
docker-compose -f docker-compose.standalone.yml up -d
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Docker Permission Issues
```bash
# Ensure Docker daemon is running
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### 2. Port Conflicts
```bash
# Check what's using the port
sudo netstat -tulpn | grep :12000

# Use different ports
./build-and-run.sh -p 3000 -s 8080
```

#### 3. Model Loading Issues
```bash
# Check if model file exists
ls -la models/

# Verify model file permissions
chmod 644 models/*.gguf

# Check container logs
docker logs devstral-openhands-deployment
```

#### 4. Memory Issues
```bash
# Check available memory
free -h

# Monitor container memory usage
docker stats devstral-openhands-deployment

# Reduce model parameters
export CONTEXT_SIZE=2048
export BATCH_SIZE=256
```

#### 5. GPU Issues
```bash
# Check NVIDIA drivers
nvidia-smi

# Verify Docker GPU support
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Enable GPU in deployment
./build-and-run.sh -t llamacpp -g
```

### Debug Mode
```bash
# Run in debug mode
docker run -it --rm \
  --privileged \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ./models:/app/models \
  devstral-openhands:latest shell

# Inside container, run commands manually
./entrypoint.sh start
```

## 🔒 Security Considerations

### Docker-in-Docker Security
- The container runs in privileged mode for Docker-in-Docker functionality
- Only use in trusted environments
- Consider using Docker socket proxy for production

### Network Security
- Services are exposed on specified ports
- Use reverse proxy with SSL for production
- Implement proper firewall rules

### Data Security
- Model files and workspace data are persistent
- Ensure proper backup strategies
- Use encrypted storage for sensitive data

## 🚀 Performance Optimization

### CPU Optimization
```bash
# Set optimal thread count
export THREADS=$(nproc)

# Adjust batch size
export BATCH_SIZE=1024
```

### Memory Optimization
```bash
# Reduce context size for lower memory usage
export CONTEXT_SIZE=2048

# Monitor memory usage
docker stats --no-stream
```

### GPU Optimization
```bash
# Enable GPU acceleration
export GPU_ENABLED=true
export GPU_LAYERS=35

# Monitor GPU usage
nvidia-smi -l 1
```

## 📚 Additional Resources

- [Main README](README.md) - General project information
- [Deployment Guide](docs/deployment-guide.md) - Detailed deployment instructions
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions
- [Examples](examples/) - Ready-to-use configuration examples

## 🤝 Contributing

To contribute to the Docker deployment:

1. Test your changes with different deployment types
2. Update documentation for any new features
3. Ensure backward compatibility
4. Add appropriate error handling

## 📄 License

This Docker deployment is part of the Devstral OpenHands project and is licensed under the MIT License.

## Frontend Image for Ollama Deployment

When `DEPLOYMENT_TYPE` is set to `ollama` (the default), the system uses the configuration from `examples/quick-start-ollama.yml`. This configuration specifies a pre-built Docker image for the OpenHands frontend service (e.g., `docker.all-hands.dev/all-hands-ai/openhands:0.40`).

The `docker-compose.simple.yml` file contains a definition to build the `openhands` service from a local `./openhands-frontend` directory. However, for the `ollama` deployment type, this local build definition is NOT used by the main `entrypoint.sh` script. Ensure that if you intend to modify the frontend, you should either rebuild the pre-built image and update the tag in `examples/quick-start-ollama.yml`, or adapt the deployment scripts if you require a local build for `ollama` mode.