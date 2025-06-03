# Complete Deployment Guide

This guide provides step-by-step instructions for deploying Devstral with OpenHands in various environments.

## Prerequisites

### System Requirements

**Minimum Requirements**:
- 8GB RAM
- 4 CPU cores
- 20GB free disk space
- Docker and Docker Compose

**Recommended Requirements**:
- 16GB+ RAM
- 8+ CPU cores
- 50GB+ free disk space
- NVIDIA GPU with 8GB+ VRAM (optional)

### Software Dependencies

1. **Docker** (version 20.10+)
2. **Docker Compose** (version 2.0+)
3. **Git** (for cloning the repository)

## Installation Steps

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd devstral-openhands-deployment
```

### Step 2: Prepare Your Model

1. **Obtain Devstral GGUF Model**:
   - Download from Hugging Face or convert from original format
   - Ensure the file is in GGUF format

2. **Place Model File**:
   ```bash
   mkdir -p models
   cp /path/to/your/devstral-model.gguf models/
   ```

### Step 3: Choose Deployment Method

#### Option A: Quick Start with Ollama (Recommended for Beginners)

```bash
# Copy the quick start configuration
cp examples/quick-start-ollama.yml docker-compose.yml

# Start the services
docker-compose up -d

# Create the model in Ollama
docker cp ollama-setup/Modelfile ollama:/tmp/
docker exec -it ollama ollama create devstral -f /tmp/Modelfile
```

#### Option B: Production Setup with Text Generation WebUI

```bash
# Copy the production configuration
cp examples/production-textgen.yml docker-compose.yml
cp text-generation-webui/settings.yaml ./

# Start the services
docker-compose up -d

# Load model via web interface at http://localhost:7860
```

#### Option C: High Performance with llama.cpp

```bash
# Copy the high-performance configuration
cp examples/high-performance-llamacpp.yml docker-compose.yml

# For CPU-only
docker-compose up -d

# For GPU acceleration
GPU_ENABLED=true GPU_LAYERS=35 docker-compose up -d
```

### Step 4: Verify Deployment

1. **Check Service Status**:
   ```bash
   docker-compose ps
   ```

2. **Test Model API**:
   ```bash
   # For Ollama
   ./ollama-setup/test-api.sh

   # For Text Generation WebUI
   ./text-generation-webui/test-api.sh

   # For llama.cpp
   ./llamacpp-server/test-api.sh
   ```

3. **Access OpenHands**:
   - Open http://localhost:3000 in your browser
   - Verify the interface loads correctly

## Environment-Specific Deployments

### Local Development

```bash
# Use development environment with all options
cp examples/development-environment.yml docker-compose.yml
docker-compose up -d
```

### Production Server

```bash
# Use production configuration with monitoring
cp examples/production-textgen.yml docker-compose.yml
docker-compose --profile monitoring up -d
```

### Cloud Deployment (AWS/GCP/Azure)

1. **Provision VM**:
   - Minimum: 4 vCPUs, 16GB RAM
   - Recommended: 8 vCPUs, 32GB RAM, GPU instance

2. **Install Docker**:
   ```bash
   # Ubuntu/Debian
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```

3. **Configure Firewall**:
   ```bash
   # Allow necessary ports
   sudo ufw allow 3000  # OpenHands
   sudo ufw allow 8080  # Model server web UI
   sudo ufw allow 11434 # Ollama API (if using)
   ```

4. **Deploy**:
   ```bash
   git clone <repository-url>
   cd devstral-openhands-deployment
   cp examples/production-textgen.yml docker-compose.yml
   docker-compose up -d
   ```

### Docker Swarm Deployment

```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c examples/production-textgen.yml devstral-stack
```

### Kubernetes Deployment

See `k8s/` directory for Kubernetes manifests (if available).

## Configuration Options

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
GPU_LAYERS=0

# Port Configuration
OPENHANDS_PORT=3000
MODEL_SERVER_PORT=8080
WEBUI_PORT=7860

# Paths
WORKSPACE_PATH=./workspace
MODELS_PATH=./models

# Security (for production)
GRAFANA_PASSWORD=secure_password
```

### Advanced Configuration

#### Custom Model Parameters

Edit the model server configuration:

```yaml
# For Ollama - edit Modelfile
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40

# For Text Generation WebUI - edit settings.yaml
temperature: 0.7
top_p: 0.9
top_k: 40

# For llama.cpp - add to command
--temperature 0.7
--top-p 0.9
--top-k 40
```

#### Resource Limits

```yaml
deploy:
  resources:
    limits:
      memory: 16G
      cpus: '8'
    reservations:
      memory: 8G
      cpus: '4'
```

## Monitoring and Maintenance

### Health Checks

All services include health checks. Monitor with:

```bash
# Check health status
docker-compose ps

# View health check logs
docker inspect <container_name> | jq '.[0].State.Health'
```

### Logging

```bash
# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f openhands
docker-compose logs -f ollama
```

### Backup and Recovery

```bash
# Backup volumes
docker run --rm -v devstral_ollama_data:/data -v $(pwd):/backup alpine tar czf /backup/ollama_backup.tar.gz -C /data .

# Restore volumes
docker run --rm -v devstral_ollama_data:/data -v $(pwd):/backup alpine tar xzf /backup/ollama_backup.tar.gz -C /data
```

### Updates

```bash
# Update images
docker-compose pull

# Restart services
docker-compose up -d
```

## Security Considerations

### Production Security

1. **Use HTTPS**:
   ```yaml
   # Add nginx with SSL termination
   nginx:
     image: nginx:alpine
     volumes:
       - ./ssl:/etc/nginx/ssl
   ```

2. **Network Security**:
   ```yaml
   # Restrict external access
   ports:
     - "127.0.0.1:3000:3000"  # Only localhost
   ```

3. **Authentication**:
   - Configure authentication in OpenHands
   - Use API keys for model servers
   - Implement reverse proxy with auth

### Firewall Configuration

```bash
# Ubuntu/Debian with ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 3000  # OpenHands (or restrict to specific IPs)
sudo ufw enable
```

## Scaling

### Horizontal Scaling

```bash
# Scale OpenHands instances
docker-compose up -d --scale openhands=3

# Use load balancer
docker-compose --profile loadbalancer up -d
```

### Vertical Scaling

```bash
# Increase resources
docker-compose -f examples/high-performance-llamacpp.yml up -d
```

## Troubleshooting

For common issues and solutions, see the [Troubleshooting Guide](troubleshooting.md).

## Next Steps

1. **Customize the model**: Adjust parameters for your use case
2. **Set up monitoring**: Enable Prometheus and Grafana
3. **Configure backups**: Set up automated backups
4. **Implement CI/CD**: Automate deployments
5. **Scale as needed**: Add more instances or resources