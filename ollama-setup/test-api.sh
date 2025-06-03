#!/bin/bash

# Test script for Ollama API endpoints
# Usage: ./test-api.sh [host] [port]

HOST=${1:-localhost}
PORT=${2:-11434}
BASE_URL="http://${HOST}:${PORT}"

echo "Testing Ollama API at ${BASE_URL}"
echo "=================================="

# Test 1: Check if Ollama is running
echo "1. Testing Ollama health..."
curl -s "${BASE_URL}/api/tags" > /dev/null
if [ $? -eq 0 ]; then
    echo "✓ Ollama is running"
else
    echo "✗ Ollama is not responding"
    exit 1
fi

# Test 2: List available models
echo -e "\n2. Available models:"
curl -s "${BASE_URL}/api/tags" | jq -r '.models[].name' 2>/dev/null || echo "No models found or jq not available"

# Test 3: Test generation endpoint
echo -e "\n3. Testing generation endpoint..."
RESPONSE=$(curl -s -X POST "${BASE_URL}/api/generate" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "devstral",
        "prompt": "Hello, how are you?",
        "stream": false
    }')

if echo "$RESPONSE" | grep -q "response"; then
    echo "✓ Generation endpoint working"
    echo "Response: $(echo "$RESPONSE" | jq -r '.response' 2>/dev/null || echo "$RESPONSE")"
else
    echo "✗ Generation endpoint failed"
    echo "Error: $RESPONSE"
fi

# Test 4: Test OpenAI-compatible endpoint
echo -e "\n4. Testing OpenAI-compatible endpoint..."
OPENAI_RESPONSE=$(curl -s -X POST "${BASE_URL}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "devstral",
        "messages": [
            {"role": "user", "content": "Say hello"}
        ]
    }')

if echo "$OPENAI_RESPONSE" | grep -q "choices"; then
    echo "✓ OpenAI-compatible endpoint working"
    echo "Response: $(echo "$OPENAI_RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null || echo "$OPENAI_RESPONSE")"
else
    echo "✗ OpenAI-compatible endpoint failed"
    echo "Error: $OPENAI_RESPONSE"
fi

echo -e "\nAPI testing complete!"