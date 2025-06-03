# llama.cpp Server Setup for Devstral

This directory contains setup instructions for using llama.cpp server to serve the Devstral model directly.

## Overview

llama.cpp server provides a lightweight HTTP server specifically designed for GGUF models with:
- Direct GGUF model loading
- OpenAI-compatible API
- Minimal resource overhead
- High performance inference

## Quick Start

1. **Run llama.cpp Server**
   ```bash
   docker-compose up -d
   ```

2. **Test the API**
   ```bash
   ./test-api.sh
   ```

## Manual Setup

### Step 1: Prepare Model

Place your Devstral GGUF file in the `./models` directory:
```bash
mkdir -p models
cp /path/to/your/devstral-model.gguf ./models/
```

### Step 2: Run Server

```bash
docker run -d \
  --name llamacpp-server \
  -p 8080:8080 \
  -v ./models:/models \
  ghcr.io/ggerganov/llama.cpp:server \
  --model /models/devstral-model.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --ctx-size 4096 \
  --n-gpu-layers 0
```

### Step 3: Test Connection

```bash
curl http://localhost:8080/v1/models
```

## Configuration Options

### Server Parameters

- `--model`: Path to GGUF model file
- `--host`: Host to bind to (use 0.0.0.0 for Docker)
- `--port`: Port to listen on
- `--ctx-size`: Context size (default: 512)
- `--threads`: Number of threads
- `--n-gpu-layers`: Number of layers to offload to GPU

### Example with GPU Support

```bash
docker run -d \
  --name llamacpp-server-gpu \
  --gpus all \
  -p 8080:8080 \
  -v ./models:/models \
  ghcr.io/ggerganov/llama.cpp:server-cuda \
  --model /models/devstral-model.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --ctx-size 4096 \
  --n-gpu-layers 35
```

## API Endpoints

The server provides OpenAI-compatible endpoints:

- **Models**: `GET /v1/models`
- **Chat Completions**: `POST /v1/chat/completions`
- **Completions**: `POST /v1/completions`
- **Embeddings**: `POST /v1/embeddings`

## Configuration for OpenHands

Use these environment variables:

```bash
LLM_API_BASE="http://llamacpp-server:8080/v1"
LLM_MODEL_NAME="devstral"  # or the actual model name from /v1/models
```

## Performance Tuning

### CPU Optimization

```bash
# For CPU-only inference
--threads $(nproc)
--ctx-size 4096
--batch-size 512
```

### GPU Optimization

```bash
# For GPU acceleration
--n-gpu-layers 35  # Adjust based on your GPU memory
--ctx-size 8192    # Larger context with GPU
--batch-size 1024
```

### Memory Management

```bash
# For limited memory systems
--ctx-size 2048
--batch-size 256
--mlock false
```

## Files in this Directory

- `docker-compose.yml` - Complete setup with llama.cpp server and OpenHands
- `docker-compose.gpu.yml` - GPU-enabled version
- `test-api.sh` - Script to test API endpoints
- `models/` - Directory for your GGUF model files
- `start-server.sh` - Helper script to start the server with custom parameters