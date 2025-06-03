#!/bin/bash

# Devstral OpenHands Build and Run Script
# This script builds and runs the complete Devstral OpenHands deployment

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

# Default values
DEPLOYMENT_TYPE="ollama"
MODEL_FILE=""
BUILD_ONLY=false
NO_CACHE=false
GPU_ENABLED=false
OPENHANDS_PORT=12000
MODEL_SERVER_PORT=12001

# Function to show usage
show_usage() {
    echo "Devstral OpenHands Build and Run Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -t, --type TYPE       Deployment type (ollama|textgen|llamacpp) [default: ollama]"
    echo "  -m, --model FILE      Path to Devstral GGUF model file"
    echo "  -g, --gpu             Enable GPU acceleration"
    echo "  -p, --port PORT       OpenHands port [default: 12000]"
    echo "  -s, --server-port PORT Model server port [default: 12001]"
    echo "  -b, --build-only      Only build the Docker image, don't run"
    echo "  -n, --no-cache        Build without using Docker cache"
    echo "  -h, --help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                    # Build and run with Ollama"
    echo "  $0 -t textgen -m /path/to/model.gguf # Run with Text Generation WebUI"
    echo "  $0 -t llamacpp -g                    # Run llama.cpp with GPU"
    echo "  $0 -b                                # Build only, don't run"
    echo "  $0 -p 3000 -s 8080                  # Custom ports"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            DEPLOYMENT_TYPE="$2"
            shift 2
            ;;
        -m|--model)
            MODEL_FILE="$2"
            shift 2
            ;;
        -g|--gpu)
            GPU_ENABLED=true
            shift
            ;;
        -p|--port)
            OPENHANDS_PORT="$2"
            shift 2
            ;;
        -s|--server-port)
            MODEL_SERVER_PORT="$2"
            shift 2
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -n|--no-cache)
            NO_CACHE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Function to check requirements
check_requirements() {
    print_status "Checking requirements..."
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "Requirements check passed"
}

# Function to prepare model
prepare_model() {
    # Create models directory if it doesn't exist
    mkdir -p models
    
    if [ -n "$MODEL_FILE" ]; then
        if [ ! -f "$MODEL_FILE" ]; then
            print_error "Model file not found: $MODEL_FILE"
            exit 1
        fi
        
        # Copy model to models directory
        MODEL_BASENAME=$(basename "$MODEL_FILE")
        print_status "Copying model file to models/$MODEL_BASENAME"
        cp "$MODEL_FILE" "models/$MODEL_BASENAME"
        
        # Update MODEL_FILE to just the basename
        MODEL_FILE="$MODEL_BASENAME"
    else
        # Check if there's already a model in the models directory
        EXISTING_MODELS=($(find models -name "*.gguf" 2>/dev/null))
        if [ ${#EXISTING_MODELS[@]} -gt 0 ]; then
            MODEL_FILE=$(basename "${EXISTING_MODELS[0]}")
            print_status "Using existing model: $MODEL_FILE"
        else
            print_warning "No model file specified and none found in models/ directory"
            print_status "You can add a model file later by copying it to the models/ directory"
            MODEL_FILE="devstral-model.gguf"
        fi
    fi
}

# Function to build Docker image
build_image() {
    print_status "Building Docker image..."
    
    BUILD_ARGS=""
    if [ "$NO_CACHE" = true ]; then
        BUILD_ARGS="--no-cache"
    fi
    
    docker build $BUILD_ARGS -t devstral-openhands:latest .
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to create environment file
create_env_file() {
    print_status "Creating environment configuration..."
    
    cat > .env.docker << EOF
# Devstral OpenHands Docker Configuration
DEPLOYMENT_TYPE=$DEPLOYMENT_TYPE
MODEL_FILE=$MODEL_FILE
MODEL_NAME=devstral
CONTEXT_SIZE=4096
THREADS=$(nproc)
BATCH_SIZE=512
GPU_LAYERS=$([ "$GPU_ENABLED" = true ] && echo "35" || echo "0")
GPU_ENABLED=$GPU_ENABLED
OPENHANDS_PORT=$OPENHANDS_PORT
MODEL_SERVER_PORT=$MODEL_SERVER_PORT
WEBUI_PORT=8080
API_PORT=5000
WORKSPACE_PATH=./workspace
MODELS_PATH=./models
EOF
    
    print_success "Environment file created: .env.docker"
}

# Function to run the deployment
run_deployment() {
    print_status "Starting Devstral OpenHands deployment..."
    
    # Create necessary directories
    mkdir -p workspace logs
    
    # Set environment variables for docker-compose
    export DEPLOYMENT_TYPE
    export MODEL_FILE
    export GPU_ENABLED
    export OPENHANDS_PORT
    export MODEL_SERVER_PORT
    
    # Start the deployment
    docker compose -f docker-compose.standalone.yml --env-file .env.docker up -d
    
    if [ $? -eq 0 ]; then
        print_success "Deployment started successfully!"
        echo
        print_status "Services are starting up. This may take a few minutes..."
        print_status "You can monitor the progress with: docker compose -f docker-compose.standalone.yml logs -f"
        echo
        print_success "Once ready, access your services at:"
        echo "  OpenHands: http://localhost:$OPENHANDS_PORT"
        case $DEPLOYMENT_TYPE in
            "ollama")
                echo "  Ollama Web UI: http://localhost:8080"
                echo "  Ollama API: http://localhost:$MODEL_SERVER_PORT"
                ;;
            "textgen")
                echo "  Text Generation WebUI: http://localhost:8080"
                echo "  API: http://localhost:5000"
                ;;
            "llamacpp")
                echo "  llama.cpp API: http://localhost:$MODEL_SERVER_PORT"
                ;;
        esac
        echo
        print_status "To stop the deployment: docker compose -f docker-compose.standalone.yml down"
        print_status "To view logs: docker compose -f docker-compose.standalone.yml logs -f"
    else
        print_error "Failed to start deployment"
        exit 1
    fi
}

# Function to show status
show_status() {
    print_status "Checking deployment status..."
    docker compose -f docker-compose.standalone.yml ps
}

# Main execution
main() {
    echo "========================================"
    echo "  Devstral OpenHands Build & Run"
    echo "========================================"
    echo
    
    print_status "Configuration:"
    echo "  Deployment Type: $DEPLOYMENT_TYPE"
    echo "  Model File: ${MODEL_FILE:-'Auto-detect'}"
    echo "  GPU Enabled: $GPU_ENABLED"
    echo "  OpenHands Port: $OPENHANDS_PORT"
    echo "  Model Server Port: $MODEL_SERVER_PORT"
    echo "  Build Only: $BUILD_ONLY"
    echo
    
    check_requirements
    prepare_model
    create_env_file
    build_image
    
    if [ "$BUILD_ONLY" = false ]; then
        run_deployment
    else
        print_success "Build completed. Image: devstral-openhands:latest"
        print_status "To run the deployment:"
        print_status "  docker compose -f docker-compose.standalone.yml --env-file .env.docker up -d"
    fi
}

# Run main function
main