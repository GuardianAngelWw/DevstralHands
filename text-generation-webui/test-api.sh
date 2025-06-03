#!/bin/bash

# Test script for Text Generation WebUI API endpoints
# Usage: ./test-api.sh [host] [port]

HOST=${1:-localhost}
PORT=${2:-5000}
BASE_URL="http://${HOST}:${PORT}"

echo "Testing Text Generation WebUI API at ${BASE_URL}"
echo "================================================"

# Test 1: Check if API is running
echo "1. Testing API health..."
curl -s "${BASE_URL}/api/v1/model" > /dev/null
if [ $? -eq 0 ]; then
    echo "✓ API is running"
else
    echo "✗ API is not responding"
    exit 1
fi

# Test 2: Get model info
echo -e "\n2. Current model info:"
MODEL_INFO=$(curl -s "${BASE_URL}/api/v1/model")
echo "$MODEL_INFO" | jq '.' 2>/dev/null || echo "$MODEL_INFO"

# Test 3: Test native generation endpoint
echo -e "\n3. Testing native generation endpoint..."
RESPONSE=$(curl -s -X POST "${BASE_URL}/api/v1/generate" \
    -H "Content-Type: application/json" \
    -d '{
        "prompt": "Hello, how are you?",
        "max_new_tokens": 100,
        "temperature": 0.7,
        "top_p": 0.9,
        "do_sample": true,
        "stopping_strings": ["<|im_end|>"]
    }')

if echo "$RESPONSE" | grep -q "results"; then
    echo "✓ Native generation endpoint working"
    echo "Response: $(echo "$RESPONSE" | jq -r '.results[0].text' 2>/dev/null || echo "$RESPONSE")"
else
    echo "✗ Native generation endpoint failed"
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
        ],
        "temperature": 0.7,
        "max_tokens": 100
    }')

if echo "$OPENAI_RESPONSE" | grep -q "choices"; then
    echo "✓ OpenAI-compatible endpoint working"
    echo "Response: $(echo "$OPENAI_RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null || echo "$OPENAI_RESPONSE")"
else
    echo "✗ OpenAI-compatible endpoint failed"
    echo "Error: $OPENAI_RESPONSE"
fi

# Test 5: Test streaming endpoint
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

echo -e "\nAPI testing complete!"