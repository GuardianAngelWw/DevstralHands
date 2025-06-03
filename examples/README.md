# Complete Deployment Examples

This directory contains complete, ready-to-use deployment examples for different scenarios.

## Available Examples

### 1. Quick Start with Ollama
**File**: `quick-start-ollama.yml`
- Simplest setup using Ollama
- Includes web UI for model management
- Best for beginners

### 2. Production Setup with Text Generation WebUI
**File**: `production-textgen.yml`
- Full-featured setup with Text Generation WebUI
- Includes monitoring and logging
- Best for production environments

### 3. High-Performance with llama.cpp
**File**: `high-performance-llamacpp.yml`
- Optimized for performance
- GPU support available
- Best for resource-intensive workloads

### 4. All-in-One Development Environment
**File**: `development-environment.yml`
- Includes all three model servers
- Useful for testing and development
- Multiple OpenHands instances

## Quick Deployment

1. **Choose your preferred setup**:
   ```bash
   # For Ollama (recommended for beginners)
   cp examples/quick-start-ollama.yml docker-compose.yml
   
   # For Text Generation WebUI (recommended for production)
   cp examples/production-textgen.yml docker-compose.yml
   
   # For llama.cpp (recommended for performance)
   cp examples/high-performance-llamacpp.yml docker-compose.yml
   ```

2. **Prepare your model**:
   ```bash
   mkdir -p models
   # Copy your Devstral GGUF file to the models directory
   cp /path/to/your/devstral-model.gguf models/
   ```

3. **Start the services**:
   ```bash
   docker-compose up -d
   ```

4. **Access the interfaces**:
   - OpenHands: http://localhost:3000
   - Model Server Web UI: http://localhost:8080 (varies by setup)

## Environment Variables

All examples support these common environment variables:

### Model Configuration
- `MODEL_FILE`: Path to your GGUF model file (default: `devstral-model.gguf`)
- `MODEL_NAME`: Name to use for the model in APIs (default: `devstral`)

### Performance Tuning
- `CONTEXT_SIZE`: Model context size (default: `4096`)
- `THREADS`: Number of CPU threads (default: `4`)
- `GPU_LAYERS`: Number of layers to offload to GPU (default: `0`)

### OpenHands Configuration
- `OPENHANDS_PORT`: Port for OpenHands web interface (default: `3000`)
- `WORKSPACE_PATH`: Path to mount as workspace (default: `./workspace`)

## Usage Examples

### Custom Model File
```bash
MODEL_FILE=my-custom-model.gguf docker-compose up -d
```

### GPU Acceleration
```bash
GPU_LAYERS=35 docker-compose -f examples/high-performance-llamacpp.yml up -d
```

### Custom Ports
```bash
OPENHANDS_PORT=8000 MODEL_SERVER_PORT=9000 docker-compose up -d
```

## Troubleshooting

See the main [troubleshooting guide](../docs/troubleshooting.md) for common issues and solutions.