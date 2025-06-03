#!/bin/bash

# Helper script to start llama.cpp server with custom parameters
# Usage: ./start-server.sh [model_file] [additional_args...]

MODEL_FILE=${1:-"./models/devstral-model.gguf"}
shift  # Remove first argument, rest are additional args

# Default parameters
DEFAULT_ARGS=(
    --host 0.0.0.0
    --port 8080
    --ctx-size 4096
    --threads 4
    --batch-size 512
    --n-gpu-layers 0
)

# Check if model file exists
if [ ! -f "$MODEL_FILE" ]; then
    echo "Error: Model file '$MODEL_FILE' not found!"
    echo "Usage: $0 [model_file] [additional_args...]"
    echo "Example: $0 ./models/devstral-model.gguf --n-gpu-layers 35"
    exit 1
fi

echo "Starting llama.cpp server with model: $MODEL_FILE"
echo "Additional arguments: $@"

# Build Docker command
DOCKER_CMD=(
    docker run -it --rm
    --name llamacpp-server
    -p 8080:8080
    -v "$(pwd)/models:/models:ro"
    ghcr.io/ggerganov/llama.cpp:server
    --model "/models/$(basename "$MODEL_FILE")"
    "${DEFAULT_ARGS[@]}"
    "$@"
)

echo "Running: ${DOCKER_CMD[*]}"
exec "${DOCKER_CMD[@]}"