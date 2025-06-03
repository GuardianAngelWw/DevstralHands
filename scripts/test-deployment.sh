#!/bin/bash

# Test script for Devstral OpenHands deployment
# This script tests all components of the deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    print_status "Testing: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        print_success "✓ $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "✗ $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to test HTTP endpoint
test_http_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    
    print_status "Testing HTTP endpoint: $name"
    
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$status_code" = "$expected_status" ]; then
        print_success "✓ $name (HTTP $status_code)"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "✗ $name (HTTP $status_code, expected $expected_status)"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to test API endpoint with JSON response
test_api_endpoint() {
    local name="$1"
    local url="$2"
    local method="${3:-GET}"
    local data="$4"
    
    print_status "Testing API endpoint: $name"
    
    local response
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        response=$(curl -s -X POST "$url" -H "Content-Type: application/json" -d "$data" 2>/dev/null || echo "")
    else
        response=$(curl -s "$url" 2>/dev/null || echo "")
    fi
    
    if [ -n "$response" ] && echo "$response" | jq . >/dev/null 2>&1; then
        print_success "✓ $name (Valid JSON response)"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "✗ $name (Invalid or empty response)"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to detect deployment type
detect_deployment_type() {
    if docker-compose ps | grep -q "ollama"; then
        echo "ollama"
    elif docker-compose ps | grep -q "text-generation-webui"; then
        echo "textgen"
    elif docker-compose ps | grep -q "llamacpp"; then
        echo "llamacpp"
    else
        echo "unknown"
    fi
}

# Main testing function
main() {
    echo "========================================"
    echo "  Devstral OpenHands Deployment Test"
    echo "========================================"
    echo
    
    # Check if docker-compose.yml exists
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found. Please run setup first."
        exit 1
    fi
    
    # Detect deployment type
    DEPLOYMENT_TYPE=$(detect_deployment_type)
    print_status "Detected deployment type: $DEPLOYMENT_TYPE"
    echo
    
    # Test 1: Docker services
    print_status "=== Testing Docker Services ==="
    
    run_test "Docker daemon" "docker info"
    run_test "Docker Compose services" "docker-compose ps | grep -q Up"
    
    # Test 2: Container health
    print_status "=== Testing Container Health ==="
    
    if docker-compose ps | grep -q "openhands.*Up"; then
        print_success "✓ OpenHands container running"
        ((TESTS_PASSED++))
    else
        print_error "✗ OpenHands container not running"
        ((TESTS_FAILED++))
    fi
    
    # Test model server based on deployment type
    case $DEPLOYMENT_TYPE in
        "ollama")
            if docker-compose ps | grep -q "ollama.*Up"; then
                print_success "✓ Ollama container running"
                ((TESTS_PASSED++))
            else
                print_error "✗ Ollama container not running"
                ((TESTS_FAILED++))
            fi
            ;;
        "textgen")
            if docker-compose ps | grep -q "text-generation-webui.*Up"; then
                print_success "✓ Text Generation WebUI container running"
                ((TESTS_PASSED++))
            else
                print_error "✗ Text Generation WebUI container not running"
                ((TESTS_FAILED++))
            fi
            ;;
        "llamacpp")
            if docker-compose ps | grep -q "llamacpp.*Up"; then
                print_success "✓ llama.cpp server container running"
                ((TESTS_PASSED++))
            else
                print_error "✗ llama.cpp server container not running"
                ((TESTS_FAILED++))
            fi
            ;;
    esac
    
    # Test 3: Network connectivity
    print_status "=== Testing Network Connectivity ==="
    
    # Test OpenHands web interface
    test_http_endpoint "OpenHands web interface" "http://localhost:3000"
    
    # Test model server APIs based on deployment type
    case $DEPLOYMENT_TYPE in
        "ollama")
            test_api_endpoint "Ollama API - Models" "http://localhost:11434/api/tags"
            test_http_endpoint "Ollama Web UI" "http://localhost:8080"
            ;;
        "textgen")
            test_api_endpoint "Text Generation WebUI API" "http://localhost:5000/api/v1/model"
            test_http_endpoint "Text Generation WebUI" "http://localhost:7860"
            ;;
        "llamacpp")
            test_api_endpoint "llama.cpp API - Models" "http://localhost:8080/v1/models"
            ;;
    esac
    
    # Test 4: Model functionality
    print_status "=== Testing Model Functionality ==="
    
    case $DEPLOYMENT_TYPE in
        "ollama")
            # Test Ollama model
            if docker exec ollama ollama list | grep -q "devstral"; then
                print_success "✓ Devstral model loaded in Ollama"
                ((TESTS_PASSED++))
                
                # Test generation
                test_api_endpoint "Ollama generation" "http://localhost:11434/api/generate" "POST" \
                    '{"model": "devstral", "prompt": "Hello", "stream": false}'
            else
                print_error "✗ Devstral model not found in Ollama"
                ((TESTS_FAILED++))
            fi
            ;;
        "textgen")
            # Test Text Generation WebUI
            test_api_endpoint "Text Generation WebUI generation" "http://localhost:5000/api/v1/generate" "POST" \
                '{"prompt": "Hello", "max_new_tokens": 10}'
            ;;
        "llamacpp")
            # Test llama.cpp server
            test_api_endpoint "llama.cpp completion" "http://localhost:8080/v1/completions" "POST" \
                '{"model": "devstral", "prompt": "Hello", "max_tokens": 10}'
            ;;
    esac
    
    # Test 5: OpenHands API integration
    print_status "=== Testing OpenHands Integration ==="
    
    # This is a basic test - in practice, you might want to test actual OpenHands functionality
    test_http_endpoint "OpenHands health check" "http://localhost:3000/api/health" "200"
    
    # Test 6: Resource usage
    print_status "=== Testing Resource Usage ==="
    
    # Check memory usage
    local memory_usage=$(docker stats --no-stream --format "table {{.MemUsage}}" | tail -n +2 | head -1 | cut -d'/' -f1 | sed 's/[^0-9.]//g')
    if [ -n "$memory_usage" ]; then
        print_success "✓ Memory usage: ${memory_usage}MB"
        ((TESTS_PASSED++))
    else
        print_warning "? Could not determine memory usage"
    fi
    
    # Check disk usage
    local disk_usage=$(df -h . | tail -1 | awk '{print $5}')
    print_success "✓ Disk usage: $disk_usage"
    ((TESTS_PASSED++))
    
    # Test 7: Log analysis
    print_status "=== Analyzing Logs ==="
    
    # Check for errors in logs
    if docker-compose logs --tail=100 2>&1 | grep -qi "error\|exception\|failed"; then
        print_warning "? Found potential errors in logs (check with: docker-compose logs)"
    else
        print_success "✓ No obvious errors in recent logs"
        ((TESTS_PASSED++))
    fi
    
    # Summary
    echo
    print_status "=== Test Summary ==="
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "All tests passed! Your deployment is working correctly."
        exit 0
    else
        print_error "Some tests failed. Please check the issues above."
        echo
        print_status "Common troubleshooting steps:"
        echo "1. Check service logs: docker-compose logs"
        echo "2. Restart services: docker-compose restart"
        echo "3. Check system resources: docker stats"
        echo "4. Verify model files are present and accessible"
        echo "5. See docs/troubleshooting.md for more help"
        exit 1
    fi
}

# Show usage
show_usage() {
    echo "Devstral OpenHands Deployment Test Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -v, --verbose    Show verbose output"
    echo "  -q, --quick      Run only basic tests"
    echo "  -h, --help       Show this help message"
    echo
    echo "This script tests your Devstral OpenHands deployment to ensure"
    echo "all components are working correctly."
}

# Parse command line arguments
VERBOSE=false
QUICK=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quick)
            QUICK=true
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

# Run main function
main