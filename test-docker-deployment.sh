#!/bin/bash

# Test script for Docker deployment
# This script tests the Docker deployment functionality

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up test environment..."
    
    # Stop and remove test containers
    docker-compose -f docker-compose.standalone.yml down -v 2>/dev/null || true
    docker stop devstral-test 2>/dev/null || true
    docker rm devstral-test 2>/dev/null || true
    
    # Remove test image
    docker rmi devstral-openhands:test 2>/dev/null || true
    
    # Remove test files
    rm -f .env.test
    rm -rf test-models test-workspace
    
    print_success "Cleanup completed"
}

# Function to check requirements
check_requirements() {
    print_status "Checking requirements..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    print_success "Requirements check passed"
}

# Function to test Docker build
test_docker_build() {
    print_status "Testing Docker build..."
    
    # Build the image with test tag
    docker build -t devstral-openhands:test .
    
    if [ $? -eq 0 ]; then
        print_success "Docker build successful"
    else
        print_error "Docker build failed"
        exit 1
    fi
}

# Function to test basic container functionality
test_container_basic() {
    print_status "Testing basic container functionality..."
    
    # Create test directories
    mkdir -p test-models test-workspace
    
    # Create a dummy model file for testing
    echo "dummy model content" > test-models/test-model.gguf
    
    # Run container in test mode
    docker run -d \
        --name devstral-test \
        --privileged \
        -p 13000:12000 \
        -p 13001:12001 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v $(pwd)/test-models:/app/models \
        -v $(pwd)/test-workspace:/app/workspace \
        -e MODEL_FILE=test-model.gguf \
        -e OPENHANDS_PORT=12000 \
        -e MODEL_SERVER_PORT=12001 \
        devstral-openhands:test shell
    
    # Wait for container to start
    sleep 5
    
    # Check if container is running
    if docker ps | grep -q devstral-test; then
        print_success "Container started successfully"
    else
        print_error "Container failed to start"
        docker logs devstral-test
        exit 1
    fi
    
    # Test basic commands inside container
    docker exec devstral-test ls -la /app
    docker exec devstral-test cat /app/.env
    
    print_success "Basic container functionality test passed"
}

# Function to test docker-compose deployment
test_docker_compose() {
    print_status "Testing docker-compose deployment..."
    
    # Create test environment file
    cat > .env.test << EOF
DEPLOYMENT_TYPE=ollama
MODEL_FILE=test-model.gguf
OPENHANDS_PORT=13000
MODEL_SERVER_PORT=13001
WEBUI_PORT=13080
EOF
    
    # Test docker-compose configuration
    docker-compose -f docker-compose.standalone.yml --env-file .env.test config > /dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Docker Compose configuration is valid"
    else
        print_error "Docker Compose configuration is invalid"
        exit 1
    fi
    
    print_success "Docker Compose test passed"
}

# Function to test build script
test_build_script() {
    print_status "Testing build script..."
    
    # Check if build script exists and is executable
    if [ ! -x "./build-and-run.sh" ]; then
        print_error "Build script is not executable"
        exit 1
    fi
    
    # Test build script help
    ./build-and-run.sh --help > /dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Build script help works"
    else
        print_error "Build script help failed"
        exit 1
    fi
    
    print_success "Build script test passed"
}

# Function to test file structure
test_file_structure() {
    print_status "Testing file structure..."
    
    # Check required files
    required_files=(
        "Dockerfile"
        "docker-compose.standalone.yml"
        "build-and-run.sh"
        "DOCKER_DEPLOYMENT.md"
        "examples/quick-start-ollama.yml"
        "ollama-setup/Modelfile"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "Required file missing: $file"
            exit 1
        fi
    done
    
    print_success "File structure test passed"
}

# Main test function
run_tests() {
    echo "========================================"
    echo "  Docker Deployment Test Suite"
    echo "========================================"
    echo
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Run tests
    check_requirements
    test_file_structure
    test_build_script
    test_docker_build
    test_container_basic
    test_docker_compose
    
    echo
    print_success "All tests passed successfully!"
    echo
    print_status "The Docker deployment is ready to use."
    print_status "Run './build-and-run.sh' to start the deployment."
}

# Handle command line arguments
case "${1:-test}" in
    "test")
        run_tests
        ;;
    "cleanup")
        cleanup
        ;;
    "build-only")
        check_requirements
        test_docker_build
        ;;
    *)
        echo "Usage: $0 {test|cleanup|build-only}"
        echo
        echo "Commands:"
        echo "  test       - Run full test suite (default)"
        echo "  cleanup    - Clean up test environment"
        echo "  build-only - Only test Docker build"
        exit 1
        ;;
esac