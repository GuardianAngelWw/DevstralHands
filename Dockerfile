# Devstral OpenHands Deployment Dockerfile
# This Dockerfile creates a control container that manages the full application deployment
# using docker-compose to orchestrate the model server and OpenHands services

FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    python3 \
    python3-pip \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && rm -rf /var/lib/apt/lists/*

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Copy repository files
COPY . .

# Make scripts executable
RUN chmod +x scripts/*.sh

# Create necessary directories
RUN mkdir -p models workspace logs

# Set environment variables with defaults
ENV DEPLOYMENT_TYPE=ollama
ENV MODEL_FILE=devstral-model.gguf
ENV MODEL_NAME=devstral
ENV CONTEXT_SIZE=4096
ENV THREADS=8
ENV BATCH_SIZE=512
ENV GPU_LAYERS=0
ENV OPENHANDS_PORT=12000
ENV MODEL_SERVER_PORT=12001
ENV WEBUI_PORT=8080
ENV API_PORT=5000
ENV WORKSPACE_PATH=./workspace
ENV MODELS_PATH=./models
ENV GPU_ENABLED=false

# Create entrypoint script
RUN cat > /app/entrypoint.sh << 'EOF'
#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to start Docker daemon
start_docker() {
    print_status "Starting Docker daemon..."
    
    # Start Docker daemon in background
    dockerd > /tmp/docker.log 2>&1 &
    
    # Wait for Docker to be ready
    for i in {1..30}; do
        if docker info >/dev/null 2>&1; then
            print_success "Docker daemon is ready"
            return 0
        fi
        print_status "Waiting for Docker daemon... ($i/30)"
        sleep 2
    done
    
    print_error "Docker daemon failed to start"
    cat /tmp/docker.log
    exit 1
}

# Function to create environment file
create_env_file() {
    print_status "Creating environment configuration..."
    
    cat > .env << EOL
# Devstral OpenHands Configuration
# Generated automatically

# Model Configuration
MODEL_FILE=${MODEL_FILE}
MODEL_NAME=${MODEL_NAME}
CONTEXT_SIZE=${CONTEXT_SIZE}

# Performance Settings
THREADS=${THREADS}
BATCH_SIZE=${BATCH_SIZE}
GPU_LAYERS=${GPU_LAYERS}

# Port Configuration
OPENHANDS_PORT=${OPENHANDS_PORT}
MODEL_SERVER_PORT=${MODEL_SERVER_PORT}
WEBUI_PORT=${WEBUI_PORT}
API_PORT=${API_PORT}

# Paths
WORKSPACE_PATH=${WORKSPACE_PATH}
MODELS_PATH=${MODELS_PATH}

# GPU Settings
GPU_ENABLED=${GPU_ENABLED}
EOL
    
    print_success "Environment file created"
}

# Function to setup deployment
setup_deployment() {
    print_status "Setting up deployment type: ${DEPLOYMENT_TYPE}"
    
    case ${DEPLOYMENT_TYPE} in
        "ollama")
            cp examples/quick-start-ollama.yml docker-compose.yml
            cp ollama-setup/Modelfile ./
            ;;
        "textgen")
            cp examples/production-textgen.yml docker-compose.yml
            if [ -f text-generation-webui/settings.yaml ]; then
                cp text-generation-webui/settings.yaml ./
            fi
            ;;
        "llamacpp")
            if [ "${GPU_ENABLED}" = "true" ]; then
                cp examples/high-performance-llamacpp.yml docker-compose.yml
            else
                cp llamacpp-server/docker-compose.yml docker-compose.yml
            fi
            ;;
        *)
            print_warning "Unknown deployment type: ${DEPLOYMENT_TYPE}. Using ollama as default."
            cp examples/quick-start-ollama.yml docker-compose.yml
            cp ollama-setup/Modelfile ./
            ;;
    esac
    
    print_success "Deployment files configured"
}

# Function to check for model file
check_model() {
    if [ ! -f "${MODELS_PATH}/${MODEL_FILE}" ]; then
        print_warning "Model file not found: ${MODELS_PATH}/${MODEL_FILE}"
        print_status "Please ensure your model file is mounted to ${MODELS_PATH}/${MODEL_FILE}"
        print_status "You can mount it using: -v /path/to/your/model.gguf:/app/${MODELS_PATH}/${MODEL_FILE}"
        
        # Create a placeholder file to prevent errors
        touch "${MODELS_PATH}/${MODEL_FILE}"
    else
        print_success "Model file found: ${MODELS_PATH}/${MODEL_FILE}"
    fi
}

# Function to start services
start_services() {
    print_status "Starting services..."
    
    # Pull images
    print_status "Pulling Docker images..."
    docker-compose pull
    
    # Start services
    print_status "Starting containers..."
    docker-compose up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to start..."
    sleep 15
    
    # Check service status
    if docker-compose ps | grep -q "Up"; then
        print_success "Services started successfully!"
        
        # Additional setup for Ollama
        if [ "${DEPLOYMENT_TYPE}" = "ollama" ]; then
            print_status "Setting up Ollama model..."
            sleep 10  # Wait for Ollama to be fully ready
            
            # Copy Modelfile and create model
            docker cp ./Modelfile $(docker-compose ps -q ollama):/tmp/ 2>/dev/null || true
            docker exec $(docker-compose ps -q ollama) ollama create ${MODEL_NAME} -f /tmp/Modelfile 2>/dev/null || {
                print_warning "Could not automatically create Ollama model."
                print_status "You may need to manually run:"
                print_status "docker exec -it \$(docker-compose ps -q ollama) ollama create ${MODEL_NAME} -f /tmp/Modelfile"
            }
        fi
        
        echo
        print_success "Deployment completed! Access your services at:"
        echo "  OpenHands: http://localhost:${OPENHANDS_PORT}"
        case ${DEPLOYMENT_TYPE} in
            "ollama")
                echo "  Ollama Web UI: http://localhost:${WEBUI_PORT}"
                echo "  Ollama API: http://localhost:${MODEL_SERVER_PORT}"
                ;;
            "textgen")
                echo "  Text Generation WebUI: http://localhost:${WEBUI_PORT}"
                echo "  API: http://localhost:${API_PORT}"
                ;;
            "llamacpp")
                echo "  llama.cpp API: http://localhost:${MODEL_SERVER_PORT}"
                ;;
        esac
        echo
        print_status "Logs can be viewed with: docker-compose logs -f"
        
    else
        print_error "Some services failed to start. Check logs with: docker-compose logs"
        docker-compose logs
        exit 1
    fi
}

# Function to show logs
show_logs() {
    print_status "Showing service logs..."
    docker-compose logs -f
}

# Main execution
main() {
    echo "========================================"
    echo "  Devstral OpenHands Deployment"
    echo "========================================"
    echo
    
    print_status "Deployment Type: ${DEPLOYMENT_TYPE}"
    print_status "Model File: ${MODEL_FILE}"
    print_status "OpenHands Port: ${OPENHANDS_PORT}"
    print_status "Model Server Port: ${MODEL_SERVER_PORT}"
    echo
    
    # Start Docker daemon
    start_docker
    
    # Setup deployment
    create_env_file
    setup_deployment
    check_model
    start_services
    
    # Keep container running and show logs
    show_logs
}

# Handle different commands
case "${1:-start}" in
    "start")
        main
        ;;
    "logs")
        docker-compose logs -f
        ;;
    "stop")
        print_status "Stopping services..."
        docker-compose down
        ;;
    "restart")
        print_status "Restarting services..."
        docker-compose restart
        ;;
    "status")
        docker-compose ps
        ;;
    "shell")
        /bin/bash
        ;;
    *)
        echo "Usage: $0 {start|logs|stop|restart|status|shell}"
        echo
        echo "Environment variables:"
        echo "  DEPLOYMENT_TYPE: ollama|textgen|llamacpp (default: ollama)"
        echo "  MODEL_FILE: name of the GGUF model file (default: devstral-model.gguf)"
        echo "  OPENHANDS_PORT: port for OpenHands web interface (default: 12000)"
        echo "  MODEL_SERVER_PORT: port for model API server (default: 12001)"
        echo "  GPU_ENABLED: true|false for GPU acceleration (default: false)"
        exit 1
        ;;
esac
EOF

# Make entrypoint executable
RUN chmod +x /app/entrypoint.sh

# Expose ports
EXPOSE 12000 12001 8080 5000

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["start"]