#!/bin/bash

# Devstral OpenHands Setup Script
# This script helps you set up the Devstral model with OpenHands

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEPLOYMENT_TYPE=""
MODEL_FILE=""
GPU_ENABLED=false
WORKSPACE_DIR="./workspace"
MODELS_DIR="./models"

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check Docker
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check available memory
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$MEMORY_GB" -lt 8 ]; then
        print_warning "System has less than 8GB RAM. Performance may be limited."
    fi
    
    # Check disk space
    DISK_SPACE_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$DISK_SPACE_GB" -lt 20 ]; then
        print_warning "Less than 20GB free disk space available."
    fi
    
    # Check for GPU
    if command_exists nvidia-smi; then
        print_status "NVIDIA GPU detected. GPU acceleration will be available."
        GPU_AVAILABLE=true
    else
        print_status "No NVIDIA GPU detected. Using CPU-only mode."
        GPU_AVAILABLE=false
    fi
    
    print_success "System requirements check completed."
}

# Function to select deployment type
select_deployment_type() {
    echo
    print_status "Select deployment type:"
    echo "1) Quick Start with Ollama (Recommended for beginners)"
    echo "2) Production Setup with Text Generation WebUI"
    echo "3) High Performance with llama.cpp"
    echo "4) Development Environment (All options)"
    echo
    
    while true; do
        read -p "Enter your choice (1-4): " choice
        case $choice in
            1)
                DEPLOYMENT_TYPE="ollama"
                break
                ;;
            2)
                DEPLOYMENT_TYPE="textgen"
                break
                ;;
            3)
                DEPLOYMENT_TYPE="llamacpp"
                break
                ;;
            4)
                DEPLOYMENT_TYPE="development"
                break
                ;;
            *)
                print_error "Invalid choice. Please enter 1-4."
                ;;
        esac
    done
    
    print_success "Selected deployment type: $DEPLOYMENT_TYPE"
}

# Function to configure model
configure_model() {
    echo
    print_status "Model configuration:"
    
    # Check if models directory exists
    if [ ! -d "$MODELS_DIR" ]; then
        mkdir -p "$MODELS_DIR"
        print_status "Created models directory: $MODELS_DIR"
    fi
    
    # Look for existing GGUF files
    GGUF_FILES=($(find "$MODELS_DIR" -name "*.gguf" 2>/dev/null))
    
    if [ ${#GGUF_FILES[@]} -gt 0 ]; then
        echo "Found existing GGUF files:"
        for i in "${!GGUF_FILES[@]}"; do
            echo "$((i+1))) $(basename "${GGUF_FILES[$i]}")"
        done
        echo "$((${#GGUF_FILES[@]}+1))) Specify a different file"
        echo
        
        while true; do
            read -p "Select a model file (1-$((${#GGUF_FILES[@]}+1))): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((${#GGUF_FILES[@]}+1)) ]; then
                if [ "$choice" -le ${#GGUF_FILES[@]} ]; then
                    MODEL_FILE=$(basename "${GGUF_FILES[$((choice-1))]}")
                    break
                else
                    # User wants to specify a different file
                    break
                fi
            else
                print_error "Invalid choice."
            fi
        done
    fi
    
    # If no model file selected, ask for path
    if [ -z "$MODEL_FILE" ]; then
        echo
        read -p "Enter the path to your Devstral GGUF file: " model_path
        
        if [ ! -f "$model_path" ]; then
            print_error "Model file not found: $model_path"
            exit 1
        fi
        
        # Copy model to models directory
        MODEL_FILE=$(basename "$model_path")
        print_status "Copying model file to $MODELS_DIR/$MODEL_FILE"
        cp "$model_path" "$MODELS_DIR/$MODEL_FILE"
    fi
    
    print_success "Model configured: $MODEL_FILE"
}

# Function to configure GPU settings
configure_gpu() {
    if [ "$GPU_AVAILABLE" = true ] && [ "$DEPLOYMENT_TYPE" = "llamacpp" ]; then
        echo
        read -p "Enable GPU acceleration? (y/n): " gpu_choice
        if [[ "$gpu_choice" =~ ^[Yy]$ ]]; then
            GPU_ENABLED=true
            print_success "GPU acceleration enabled."
        fi
    fi
}

# Function to create environment file
create_env_file() {
    print_status "Creating environment configuration..."
    
    cat > .env << EOF
# Devstral OpenHands Configuration
# Generated by setup script on $(date)

# Model Configuration
MODEL_FILE=$MODEL_FILE
MODEL_NAME=devstral
CONTEXT_SIZE=4096

# Performance Settings
THREADS=$(nproc)
BATCH_SIZE=512
GPU_LAYERS=$([ "$GPU_ENABLED" = true ] && echo "35" || echo "0")

# Port Configuration
OPENHANDS_PORT=3000
MODEL_SERVER_PORT=8080
WEBUI_PORT=7860
API_PORT=5000

# Paths
WORKSPACE_PATH=$WORKSPACE_DIR
MODELS_PATH=$MODELS_DIR

# GPU Settings
GPU_ENABLED=$GPU_ENABLED
EOF
    
    print_success "Environment file created: .env"
}

# Function to setup deployment
setup_deployment() {
    print_status "Setting up deployment files..."
    
    case $DEPLOYMENT_TYPE in
        "ollama")
            cp examples/quick-start-ollama.yml docker-compose.yml
            cp ollama-setup/Modelfile ./
            ;;
        "textgen")
            cp examples/production-textgen.yml docker-compose.yml
            cp text-generation-webui/settings.yaml ./
            ;;
        "llamacpp")
            if [ "$GPU_ENABLED" = true ]; then
                cp examples/high-performance-llamacpp.yml docker-compose.yml
            else
                cp llamacpp-server/docker-compose.yml docker-compose.yml
            fi
            ;;
        "development")
            cp examples/development-environment.yml docker-compose.yml
            ;;
    esac
    
    # Create workspace directory
    if [ ! -d "$WORKSPACE_DIR" ]; then
        mkdir -p "$WORKSPACE_DIR"
        print_status "Created workspace directory: $WORKSPACE_DIR"
    fi
    
    print_success "Deployment files configured."
}

# Function to start services
start_services() {
    echo
    read -p "Start services now? (y/n): " start_choice
    if [[ "$start_choice" =~ ^[Yy]$ ]]; then
        print_status "Starting services..."
        
        # Pull images first
        docker-compose pull
        
        # Start services
        docker-compose up -d
        
        # Wait for services to be ready
        print_status "Waiting for services to start..."
        sleep 10
        
        # Check service status
        if docker-compose ps | grep -q "Up"; then
            print_success "Services started successfully!"
            
            # Additional setup for Ollama
            if [ "$DEPLOYMENT_TYPE" = "ollama" ]; then
                print_status "Setting up Ollama model..."
                sleep 5  # Wait a bit more for Ollama to be ready
                docker exec -it ollama ollama create devstral -f /tmp/Modelfile 2>/dev/null || {
                    print_warning "Could not automatically create Ollama model. Please run:"
                    echo "docker cp ./Modelfile ollama:/tmp/"
                    echo "docker exec -it ollama ollama create devstral -f /tmp/Modelfile"
                }
            fi
            
            echo
            print_success "Setup completed! Access your services at:"
            echo "  OpenHands: http://localhost:3000"
            case $DEPLOYMENT_TYPE in
                "ollama")
                    echo "  Ollama Web UI: http://localhost:8080"
                    ;;
                "textgen")
                    echo "  Text Generation WebUI: http://localhost:7860"
                    echo "  API: http://localhost:5000"
                    ;;
                "llamacpp")
                    echo "  llama.cpp API: http://localhost:8080"
                    ;;
            esac
        else
            print_error "Some services failed to start. Check logs with: docker-compose logs"
        fi
    else
        print_success "Setup completed! Start services with: docker-compose up -d"
    fi
}

# Function to show usage
show_usage() {
    echo "Devstral OpenHands Setup Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -t, --type TYPE       Deployment type (ollama|textgen|llamacpp|development)"
    echo "  -m, --model FILE      Path to Devstral GGUF model file"
    echo "  -g, --gpu             Enable GPU acceleration (for llamacpp)"
    echo "  -w, --workspace DIR   Workspace directory (default: ./workspace)"
    echo "  -h, --help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                    # Interactive setup"
    echo "  $0 -t ollama -m /path/to/model.gguf  # Quick setup with Ollama"
    echo "  $0 -t llamacpp -m model.gguf -g      # llama.cpp with GPU"
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
        -w|--workspace)
            WORKSPACE_DIR="$2"
            shift 2
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

# Main execution
main() {
    echo "========================================"
    echo "  Devstral OpenHands Setup Script"
    echo "========================================"
    echo
    
    check_requirements
    
    # Interactive mode if no deployment type specified
    if [ -z "$DEPLOYMENT_TYPE" ]; then
        select_deployment_type
    fi
    
    # Configure model if not specified
    if [ -z "$MODEL_FILE" ]; then
        configure_model
    fi
    
    configure_gpu
    create_env_file
    setup_deployment
    start_services
    
    echo
    print_success "Setup completed successfully!"
}

# Run main function
main