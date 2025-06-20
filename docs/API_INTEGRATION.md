# Devstral OpenHands Integration Guide

This document explains how the Devstral model integrates with OpenHands frontend, particularly focusing on the API key and model prompt handling.

## Integration Overview

The OpenHands frontend requires proper configuration to seamlessly connect with the Ollama backend running the Devstral model. Without the correct environment variables, users may be prompted for API keys or model selection even though direct integration is intended.

## Environment Variables for Direct Integration

The following environment variables have been added to solve the API key and model prompt issues:

```yaml
- LLM_API_KEY=sk-devstral-integration  # Provide a default API key to skip the prompt
- SKIP_API_KEY_VALIDATION=true  # Skip API key validation
- AUTO_CONNECT_MODEL=true  # Automatically connect to the model without prompting
- DEFAULT_MODEL=devstral  # Set default model to use
- DIRECT_MODEL_INTEGRATION=true  # Enable direct model integration
```

### Explanation

1. **LLM_API_KEY**: Provides a default API key, which prevents OpenHands from prompting the user for an API key. The value doesn't matter for Ollama integration, but must be present.

2. **SKIP_API_KEY_VALIDATION**: Prevents OpenHands from validating the API key with the LLM provider, allowing direct connection.

3. **AUTO_CONNECT_MODEL**: When set to `true`, OpenHands will automatically connect to the model specified in `LLM_MODEL_NAME` without prompting the user.

4. **DEFAULT_MODEL**: Specifies the default model to use if not otherwise specified.

5. **DIRECT_MODEL_INTEGRATION**: Enables the direct integration path in OpenHands, bypassing the standard API key and model selection workflow.

## Implementation

These environment variables have been added to:

1. `ollama-setup/docker-compose.yml` - For developers using the Ollama setup directly
2. `examples/quick-start-ollama.yml` - For users following the quick start guide

## Testing the Integration

After starting the containers with the updated configuration, OpenHands should automatically connect to the Devstral model without prompting for an API key or model selection.

To verify the integration is working correctly:

1. Start the containers:
   ```bash
   docker-compose -f docker-compose.standalone.yml up -d
   ```

2. Access OpenHands at: http://localhost:3000

3. The interface should be immediately usable with the Devstral model, without any additional setup or API key requirements.

## Troubleshooting

If you're still prompted for an API key or model selection, check the following:

- Ensure all the environment variables above are properly set in your Docker Compose file
- Verify the Ollama service is healthy and the Devstral model is loaded
- Check container logs for any errors:
  ```bash
  docker-compose logs openhands
  ```