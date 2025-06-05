# Devstral OpenHands Deployment Dockerfile
# This Dockerfile creates a control container that manages the full application deployment
# using docker-compose to orchestrate the model server and OpenHands services

FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    python3 \
    python3-pip \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && rm -rf /var/lib/apt/lists/*

# Docker Compose is already installed as a plugin with Docker CE
# Create a symlink for backward compatibility
RUN ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# Copy repository files
COPY . .

# Make scripts executable
RUN chmod +x scripts/*.sh

# Create necessary directories
RUN mkdir -p models workspace logs

# Set environment variables with defaults
ENV DEPLOYMENT_TYPE=ollama
ENV MODEL_FILE=devstral-model.gguf
ENV MODEL_NAME=devstral
ENV CONTEXT_SIZE=4096
ENV THREADS=8
ENV BATCH_SIZE=512
ENV GPU_LAYERS=0
ENV OPENHANDS_PORT=3000
ENV MODEL_SERVER_PORT=11434
ENV WEBUI_PORT=8080
ENV API_PORT=5000
ENV WORKSPACE_PATH=./workspace
ENV MODELS_PATH=./models
ENV GPU_ENABLED=false

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh

# Make entrypoint executable
RUN chmod +x /app/entrypoint.sh

# Expose ports (only the main ports we need)
EXPOSE 3000 11434

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["start"]