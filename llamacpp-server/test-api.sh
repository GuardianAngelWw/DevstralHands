#!/bin/bash

# Test script for llama.cpp server API endpoints
# Usage: ./test-api.sh [host] [port]

HOST=${1:-localhost}
PORT=${2:-8080}
BASE_URL="http://${HOST}:${PORT}"

echo "Testing llama.cpp server API at ${BASE_URL}"
echo "============================================"

# Test 1: Check if server is running
echo "1. Testing server health..."
curl -s "${BASE_URL}/v1/models" > /dev/null
if [ $? -eq 0 ]; then
    echo "✓ Server is running"
else
    echo "✗ Server is not responding"
    exit 1
fi

# Test 2: Get available models
echo -e "\n2. Available models:"
MODELS=$(curl -s "${BASE_URL}/v1/models")
echo "$MODELS" | jq -r '.data[].id' 2>/dev/null || echo "$MODELS"

# Test 3: Test completion endpoint
echo -e "\n3. Testing completion endpoint..."
COMPLETION_RESPONSE=$(curl -s -X POST "${BASE_URL}/v1/completions" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "devstral",
        "prompt": "Hello, how are you?",
        "max_tokens": 100,
        "temperature": 0.7,
        "top_p": 0.9
    }')

if echo "$COMPLETION_RESPONSE" | grep -q "choices"; then
    echo "✓ Completion endpoint working"
    echo "Response: $(echo "$COMPLETION_RESPONSE" | jq -r '.choices[0].text' 2>/dev/null || echo "$COMPLETION_RESPONSE")"
else
    echo "✗ Completion endpoint failed"
    echo "Error: $COMPLETION_RESPONSE"
fi

# Test 4: Test chat completions endpoint
echo -e "\n4. Testing chat completions endpoint..."
CHAT_RESPONSE=$(curl -s -X POST "${BASE_URL}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "devstral",
        "messages": [
            {"role": "user", "content": "Say hello"}
        ],
        "temperature": 0.7,
        "max_tokens": 100
    }')

if echo "$CHAT_RESPONSE" | grep -q "choices"; then
    echo "✓ Chat completions endpoint working"
    echo "Response: $(echo "$CHAT_RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null || echo "$CHAT_RESPONSE")"
else
    echo "✗ Chat completions endpoint failed"
    echo "Error: $CHAT_RESPONSE"
fi

# Test 5: Test streaming
echo -e "\n5. Testing streaming endpoint..."
STREAM_RESPONSE=$(curl -s -X POST "${BASE_URL}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "devstral",
        "messages": [
            {"role": "user", "content": "Count to 3"}
        ],
        "stream": true,
        "max_tokens": 50
    }' | head -n 5)

if echo "$STREAM_RESPONSE" | grep -q "data:"; then
    echo "✓ Streaming endpoint working"
    echo "Sample stream data: $(echo "$STREAM_RESPONSE" | head -n 2)"
else
    echo "✗ Streaming endpoint failed"
    echo "Error: $STREAM_RESPONSE"
fi

# Test 6: Get server health/stats
echo -e "\n6. Server health and stats:"
HEALTH=$(curl -s "${BASE_URL}/health" 2>/dev/null || echo "Health endpoint not available")
echo "$HEALTH"

echo -e "\nAPI testing complete!"