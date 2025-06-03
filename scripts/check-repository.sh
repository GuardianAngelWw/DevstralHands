#!/bin/bash

# Repository structure and completeness check script

# Don't exit on first error, we want to check everything
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if file exists and is not empty
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        if [ -s "$file" ]; then
            print_success "✓ $description: $file"
            return 0
        else
            print_warning "? $description exists but is empty: $file"
            return 1
        fi
    else
        print_error "✗ $description missing: $file"
        return 1
    fi
}

# Check if directory exists
check_directory() {
    local dir="$1"
    local description="$2"
    
    if [ -d "$dir" ]; then
        print_success "✓ $description: $dir"
        return 0
    else
        print_error "✗ $description missing: $dir"
        return 1
    fi
}

# Check if script is executable
check_executable() {
    local script="$1"
    local description="$2"
    
    if [ -f "$script" ] && [ -x "$script" ]; then
        print_success "✓ $description executable: $script"
        return 0
    elif [ -f "$script" ]; then
        print_warning "? $description exists but not executable: $script"
        return 1
    else
        print_error "✗ $description missing: $script"
        return 1
    fi
}

main() {
    echo "========================================"
    echo "  Repository Structure Check"
    echo "========================================"
    echo
    
    local checks_passed=0
    local checks_failed=0
    
    # Core files
    print_status "=== Core Repository Files ==="
    check_file "README.md" "Main README" && ((checks_passed++)) || ((checks_failed++))
    check_file "LICENSE" "License file" && ((checks_passed++)) || ((checks_failed++))
    check_file ".gitignore" "Git ignore file" && ((checks_passed++)) || ((checks_failed++))
    
    # Ollama setup
    print_status "=== Ollama Setup ==="
    check_directory "ollama-setup" "Ollama directory" && ((checks_passed++)) || ((checks_failed++))
    check_file "ollama-setup/README.md" "Ollama README" && ((checks_passed++)) || ((checks_failed++))
    check_file "ollama-setup/docker-compose.yml" "Ollama Docker Compose" && ((checks_passed++)) || ((checks_failed++))
    check_file "ollama-setup/Modelfile" "Ollama Modelfile" && ((checks_passed++)) || ((checks_failed++))
    check_executable "ollama-setup/test-api.sh" "Ollama test script" && ((checks_passed++)) || ((checks_failed++))
    
    # Text Generation WebUI setup
    print_status "=== Text Generation WebUI Setup ==="
    check_directory "text-generation-webui" "Text Generation WebUI directory" && ((checks_passed++)) || ((checks_failed++))
    check_file "text-generation-webui/README.md" "WebUI README" && ((checks_passed++)) || ((checks_failed++))
    check_file "text-generation-webui/docker-compose.yml" "WebUI Docker Compose" && ((checks_passed++)) || ((checks_failed++))
    check_file "text-generation-webui/settings.yaml" "WebUI settings" && ((checks_passed++)) || ((checks_failed++))
    check_executable "text-generation-webui/test-api.sh" "WebUI test script" && ((checks_passed++)) || ((checks_failed++))
    
    # llama.cpp server setup
    print_status "=== llama.cpp Server Setup ==="
    check_directory "llamacpp-server" "llama.cpp directory" && ((checks_passed++)) || ((checks_failed++))
    check_file "llamacpp-server/README.md" "llama.cpp README" && ((checks_passed++)) || ((checks_failed++))
    check_file "llamacpp-server/docker-compose.yml" "llama.cpp Docker Compose" && ((checks_passed++)) || ((checks_failed++))
    check_file "llamacpp-server/docker-compose.gpu.yml" "llama.cpp GPU Docker Compose" && ((checks_passed++)) || ((checks_failed++))
    check_executable "llamacpp-server/test-api.sh" "llama.cpp test script" && ((checks_passed++)) || ((checks_failed++))
    check_executable "llamacpp-server/start-server.sh" "llama.cpp start script" && ((checks_passed++)) || ((checks_failed++))
    
    # Examples
    print_status "=== Examples ==="
    check_directory "examples" "Examples directory" && ((checks_passed++)) || ((checks_failed++))
    check_file "examples/README.md" "Examples README" && ((checks_passed++)) || ((checks_failed++))
    check_file "examples/quick-start-ollama.yml" "Quick start example" && ((checks_passed++)) || ((checks_failed++))
    check_file "examples/production-textgen.yml" "Production example" && ((checks_passed++)) || ((checks_failed++))
    check_file "examples/high-performance-llamacpp.yml" "High performance example" && ((checks_passed++)) || ((checks_failed++))
    
    # Documentation
    print_status "=== Documentation ==="
    check_directory "docs" "Documentation directory" && ((checks_passed++)) || ((checks_failed++))
    check_file "docs/deployment-guide.md" "Deployment guide" && ((checks_passed++)) || ((checks_failed++))
    check_file "docs/troubleshooting.md" "Troubleshooting guide" && ((checks_passed++)) || ((checks_failed++))
    
    # Scripts
    print_status "=== Scripts ==="
    check_directory "scripts" "Scripts directory" && ((checks_passed++)) || ((checks_failed++))
    check_executable "scripts/setup.sh" "Setup script" && ((checks_passed++)) || ((checks_failed++))
    check_executable "scripts/test-deployment.sh" "Test deployment script" && ((checks_passed++)) || ((checks_failed++))
    check_executable "scripts/check-repository.sh" "Repository check script" && ((checks_passed++)) || ((checks_failed++))
    
    # Docker Compose validation (skip if Docker not available)
    print_status "=== Docker Compose Validation ==="
    
    if command -v docker >/dev/null 2>&1 && (command -v docker-compose >/dev/null 2>&1 || docker compose version >/dev/null 2>&1); then
        for compose_file in ollama-setup/docker-compose.yml text-generation-webui/docker-compose.yml llamacpp-server/docker-compose.yml llamacpp-server/docker-compose.gpu.yml examples/*.yml; do
            if [ -f "$compose_file" ]; then
                if docker-compose -f "$compose_file" config >/dev/null 2>&1 || docker compose -f "$compose_file" config >/dev/null 2>&1; then
                    print_success "✓ Valid Docker Compose: $compose_file"
                    ((checks_passed++))
                else
                    print_error "✗ Invalid Docker Compose: $compose_file"
                    ((checks_failed++))
                fi
            fi
        done
    else
        print_warning "? Docker not available, skipping Docker Compose validation"
        print_status "Note: Docker Compose files will be validated when Docker is available"
        # Don't count this as a failure since it's an environment limitation
    fi
    
    # Summary
    echo
    print_status "=== Repository Check Summary ==="
    echo "Checks passed: $checks_passed"
    echo "Checks failed: $checks_failed"
    echo "Total checks: $((checks_passed + checks_failed))"
    
    if [ $checks_failed -eq 0 ]; then
        print_success "Repository is complete and ready for use!"
        echo
        print_status "Next steps:"
        echo "1. Add your Devstral GGUF model to the models/ directory"
        echo "2. Run ./scripts/setup.sh for interactive setup"
        echo "3. Or use one of the examples: cp examples/quick-start-ollama.yml docker-compose.yml"
        exit 0
    else
        print_error "Repository has some issues that need to be addressed."
        exit 1
    fi
}

# Show usage
show_usage() {
    echo "Repository Structure Check Script"
    echo
    echo "Usage: $0"
    echo
    echo "This script checks the completeness and structure of the"
    echo "Devstral OpenHands deployment repository."
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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

# Run main function
main