# Ollama Setup for Devstral Model

This directory contains instructions and files for setting up Ollama to serve the Devstral model.

## Quick Start

1. **Run Ollama Container**
   ```bash
   docker run -d --name ollama -p 11434:11434 -v ollama:/root/.ollama ollama/ollama
   ```

2. **Load Devstral Model**
   
   **Option A: If available on Ollama Hub**
   ```bash
   docker exec -it ollama ollama pull devstral:latest
   ```
   
   **Option B: Create from GGUF file**
   ```bash
   # Copy your GGUF file and Modelfile to the container
   docker cp ./devstral-model.gguf ollama:/tmp/devstral-model.gguf
   docker cp ./Modelfile ollama:/tmp/Modelfile
   
   # Create the model in Ollama
   docker exec -it ollama ollama create devstral -f /tmp/Modelfile
   ```

3. **Test the Model**
   ```bash
   docker exec -it ollama ollama run devstral "Hello, how are you?"
   ```

## Modelfile Example

If you need to create a model from your GGUF file, use the provided `Modelfile` template.

## API Endpoints

Once running, Ollama provides these endpoints:

- **Generate**: `POST http://localhost:11434/api/generate`
- **Chat**: `POST http://localhost:11434/api/chat`
- **OpenAI Compatible**: `POST http://localhost:11434/v1/chat/completions`

## Configuration for OpenHands

Use these environment variables when running OpenHands:

```bash
LLM_API_BASE="http://ollama:11434/v1"
LLM_MODEL_NAME="devstral"
```

## Files in this Directory

- `Modelfile` - Template for creating Devstral model from GGUF
- `docker-compose.yml` - Complete setup with Ollama and OpenHands
- `test-api.sh` - Script to test the Ollama API