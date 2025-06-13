// Configuration override for Devstral direct connection
export const DEVSTRAL_CONFIG = {
  apiBase: process.env.REACT_APP_LLM_API_BASE || 'http://ollama:11434/v1',
  modelName: process.env.REACT_APP_LLM_MODEL_NAME || 'devstral',
  requireApiKey: false,
  skipAuth: true,
  autoConnect: true
};

// Prevent configuration prompts
localStorage.setItem("openhands_config", JSON.stringify({
  apiKey: "devstral-direct-connection",
  modelName: DEVSTRAL_CONFIG.modelName,
  skipAuth: true,
  initialized: true
}));
