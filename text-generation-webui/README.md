# Text Generation WebUI Setup for Devstral

This directory contains setup instructions for using oobabooga's Text Generation WebUI to serve the Devstral model.

## Overview

Text Generation WebUI is a versatile web interface for running Large Language Models with support for:
- GGUF models
- OpenAI-compatible API
- Web interface for model management
- Multiple backends (llama.cpp, ExLlama, etc.)

## Quick Start

1. **Run Text Generation WebUI**
   ```bash
   docker-compose up -d
   ```

2. **Access Web Interface**
   - Open http://localhost:7860 in your browser
   - Go to the "Model" tab
   - Load your Devstral GGUF model

3. **Enable API**
   - Go to "Session" tab
   - Enable "api" extension
   - Restart the interface

## Manual Setup

### Step 1: Run Container

```bash
docker run -d \
  --name text-generation-webui \
  -p 7860:7860 \
  -p 5000:5000 \
  -v ./models:/app/models \
  -v ./characters:/app/characters \
  -v ./presets:/app/presets \
  -v ./prompts:/app/prompts \
  -v ./training:/app/training \
  -e EXTRA_LAUNCH_ARGS="--listen --api --api-port 5000" \
  oobabooga/text-generation-webui:latest
```

### Step 2: Load Devstral Model

1. Place your Devstral GGUF file in the `./models` directory
2. Access the web interface at http://localhost:7860
3. Go to the "Model" tab
4. Select your Devstral model from the dropdown
5. Click "Load"

### Step 3: Configure API

The API will be available at:
- **OpenAI-compatible**: `http://localhost:5000/v1/chat/completions`
- **Native API**: `http://localhost:5000/api/v1/generate`

## Configuration for OpenHands

Use these environment variables:

```bash
LLM_API_BASE="http://text-generation-webui:5000/v1"
LLM_MODEL_NAME="devstral"  # or your specific model name
```

## Advanced Configuration

### Custom Parameters

Create a `settings.yaml` file to customize model parameters:

```yaml
# Model loading
model: devstral-model.gguf
loader: llama.cpp

# Generation parameters
temperature: 0.7
top_p: 0.9
top_k: 40
repetition_penalty: 1.1
max_new_tokens: 2048

# API settings
api: true
api_port: 5000
listen: true
```

### Extensions

Useful extensions for this setup:
- `api` - Enables OpenAI-compatible API
- `openai` - Enhanced OpenAI compatibility
- `character` - Character-based conversations

## Files in this Directory

- `docker-compose.yml` - Complete setup with Text Generation WebUI and OpenHands
- `settings.yaml` - Example configuration file
- `test-api.sh` - Script to test the API endpoints
- `models/` - Directory for your GGUF model files