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

# Function to start Docker daemon with appropriate permissions
start_docker() {
    print_status "Starting Docker daemon..."

    # Ensure proper permissions for Docker socket and directories
    if [ -e /var/run/docker.sock ]; then
        chmod 666 /var/run/docker.sock
        print_status "Set permissions on Docker socket"
    fi

    # Create required directories with proper permissions
    mkdir -p /var/lib/docker
    chmod 711 /var/lib/docker

    # Disable IPv6 to avoid ip6tables errors, with read-only filesystem handling
    if [ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ]; then
        # Try to disable IPv6, but don't fail if filesystem is read-only
        echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null || {
            print_warning "Could not disable IPv6 (read-only filesystem). This is OK in containerized environments."
        }
    fi
    
    # Check if we're running as root, if not try to use sudo for dockerd
    if [ "$(id -u)" != "0" ]; then
        print_status "Running as non-root user, using sudo for Docker operations"
        DOCKER_CMD="sudo dockerd"
    else
        DOCKER_CMD="dockerd"
    fi

    # Start Docker daemon in background with proper settings to avoid permission issues
    $DOCKER_CMD \
      --iptables=false \
      --ipv6=false \
      --storage-driver=vfs \
      --bridge=none \
      --data-root=/var/lib/docker \
      > /tmp/docker.log 2>&1 &

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

# Function to start services with proper network setup
start_services() {
    print_status "Starting services..."

    # Create custom bridge network with host networking for better compatibility
    print_status "Creating Docker network for improved container communication..."
    docker network create --driver bridge devstral-network 2>/dev/null || true

    # Pull images
    print_status "Pulling Docker images..."
    docker compose -f docker-compose.yml pull

    # Start services
    print_status "Starting containers..."
    
    # Use simplified network mode if regular startup fails
    if ! docker compose -f docker-compose.yml up -d; then
        print_warning "Container startup encountered network issues, trying alternative configuration..."
        
        # Modify docker-compose to use host network if bridge creation fails
        sed -i 's/bridge:/host:/g' docker-compose.yml 2>/dev/null || true
        
        # Try again with host networking
        if ! docker compose -f docker-compose.yml up -d; then
            print_error "Failed to start containers even with alternative network configuration"
            docker compose -f docker-compose.yml logs
            exit 1
        fi
    fi

    # Wait for services to be ready
    print_status "Waiting for services to start..."
    sleep 15

    # Check service status
    if docker compose -f docker-compose.yml ps | grep -q "Up"; then
        print_success "Services started successfully!"

        # Additional setup for Ollama
        if [ "${DEPLOYMENT_TYPE}" = "ollama" ]; then
            print_status "Setting up Ollama model..."
            sleep 10  # Wait for Ollama to be fully ready

            # Copy Modelfile and create model
            docker cp ./Modelfile $(docker compose -f docker-compose.yml ps -q ollama):/tmp/ 2>/dev/null || true
            docker exec $(docker compose -f docker-compose.yml ps -q ollama) ollama create ${MODEL_NAME} -f /tmp/Modelfile 2>/dev/null || {
                print_warning "Could not automatically create Ollama model."
                print_status "You may need to manually run:"
                print_status "docker exec -it \$(docker compose -f docker-compose.yml ps -q ollama) ollama create ${MODEL_NAME} -f /tmp/Modelfile"
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
        print_status "Logs can be viewed with: docker compose -f docker-compose.yml logs -f"

    else
        print_error "Some services failed to start. Check logs with: docker compose -f docker-compose.yml logs"
        docker compose -f docker-compose.yml logs
        exit 1
    fi
}

# Function to show logs
show_logs() {
    print_status "Showing service logs..."
    docker compose -f docker-compose.yml logs -f
}

# Main execution
main() {
    echo "=================================="
    echo "  Devstral OpenHands Deployment"
    echo "=================================="
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
        docker compose -f docker-compose.yml logs -f
        ;;
    "stop")
        print_status "Stopping services..."
        docker compose -f docker-compose.yml down
        ;;
    "restart")
        print_status "Restarting services..."
        docker compose -f docker-compose.yml restart
        ;;
    "status")
        docker compose -f docker-compose.yml ps
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