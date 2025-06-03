# Troubleshooting Guide

This guide covers common issues and their solutions when deploying Devstral with OpenHands.

## Common Issues

### 1. Docker Image Pull Failures

**Problem**: Cannot pull OpenHands Docker image
```
Error response from daemon: repository public.ecr.aws/open-hands/open-hands not found
```

**Solution**: Use the correct image path
```bash
# Correct image path (updated)
docker pull docker.all-hands.dev/all-hands-ai/openhands:0.40

# Also pull the runtime image
docker pull docker.all-hands.dev/all-hands-ai/runtime:0.40-nikolaik
```

### 2. Model Loading Issues

**Problem**: Model fails to load in Ollama
```
Error: model 'devstral' not found
```

**Solutions**:
1. **Check if model exists**:
   ```bash
   docker exec -it ollama ollama list
   ```

2. **Create model from GGUF**:
   ```bash
   # Copy files to container
   docker cp ./devstral-model.gguf ollama:/tmp/
   docker cp ./Modelfile ollama:/tmp/
   
   # Create model
   docker exec -it ollama ollama create devstral -f /tmp/Modelfile
   ```

3. **Verify model file path**:
   ```bash
   # Check if file exists in container
   docker exec -it ollama ls -la /models/
   ```

### 3. API Connection Issues

**Problem**: OpenHands cannot connect to model API
```
Connection refused to http://ollama:11434
```

**Solutions**:
1. **Check network connectivity**:
   ```bash
   # Test from OpenHands container
   docker exec -it openhands curl http://ollama:11434/api/tags
   ```

2. **Verify services are on same network**:
   ```bash
   docker network ls
   docker network inspect <network_name>
   ```

3. **Check service health**:
   ```bash
   docker-compose ps
   docker-compose logs ollama
   ```

### 4. Memory Issues

**Problem**: Out of memory errors during model loading
```
RuntimeError: CUDA out of memory
```

**Solutions**:
1. **Reduce context size**:
   ```yaml
   command: >
     --ctx-size 2048  # Reduce from 4096
   ```

2. **Adjust GPU layers**:
   ```yaml
   command: >
     --n-gpu-layers 20  # Reduce from 35
   ```

3. **Use CPU-only mode**:
   ```yaml
   command: >
     --n-gpu-layers 0
   ```

### 5. Performance Issues

**Problem**: Slow response times

**Solutions**:
1. **Optimize thread count**:
   ```bash
   # Set to number of CPU cores
   --threads $(nproc)
   ```

2. **Increase batch size**:
   ```bash
   --batch-size 1024  # Increase from 512
   ```

3. **Use GPU acceleration**:
   ```bash
   --n-gpu-layers 35
   ```

### 6. Port Conflicts

**Problem**: Port already in use
```
Error: bind: address already in use
```

**Solutions**:
1. **Change ports in docker-compose.yml**:
   ```yaml
   ports:
     - "3001:3000"  # Change from 3000:3000
   ```

2. **Stop conflicting services**:
   ```bash
   # Find what's using the port
   sudo lsof -i :3000
   
   # Stop the service
   sudo kill -9 <PID>
   ```

### 7. Permission Issues

**Problem**: Docker socket permission denied
```
Permission denied while trying to connect to Docker daemon
```

**Solutions**:
1. **Add user to docker group**:
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

2. **Run with sudo** (not recommended for production):
   ```bash
   sudo docker-compose up -d
   ```

## Debugging Commands

### Check Service Status
```bash
# View all services
docker-compose ps

# Check specific service logs
docker-compose logs -f ollama
docker-compose logs -f openhands

# Check service health
docker-compose exec ollama curl http://localhost:11434/api/tags
```

### Test API Endpoints
```bash
# Test Ollama API
curl http://localhost:11434/api/tags

# Test Text Generation WebUI API
curl http://localhost:5000/api/v1/model

# Test llama.cpp server API
curl http://localhost:8080/v1/models
```

### Monitor Resource Usage
```bash
# Check container resource usage
docker stats

# Check system resources
htop
nvidia-smi  # For GPU usage
```

### Network Debugging
```bash
# List Docker networks
docker network ls

# Inspect network
docker network inspect <network_name>

# Test connectivity between containers
docker exec -it openhands ping ollama
```

## Performance Optimization

### CPU Optimization
- Set `--threads` to match your CPU cores
- Use `--batch-size 512` or higher
- Enable `--numa` for multi-socket systems

### GPU Optimization
- Set `--n-gpu-layers` based on your GPU memory
- Use larger `--ctx-size` with GPU
- Monitor GPU memory with `nvidia-smi`

### Memory Optimization
- Reduce `--ctx-size` if running out of memory
- Use `--mlock` to prevent swapping
- Set appropriate Docker memory limits

## Getting Help

If you're still experiencing issues:

1. **Check the logs**:
   ```bash
   docker-compose logs --tail=100
   ```

2. **Verify your setup**:
   - Model file exists and is accessible
   - All required ports are available
   - Sufficient system resources

3. **Test components individually**:
   - Start only the model server first
   - Test API endpoints manually
   - Add OpenHands once model server is working

4. **Check official documentation**:
   - [OpenHands Documentation](https://docs.all-hands.dev/)
   - [Ollama Documentation](https://ollama.ai/docs)
   - [llama.cpp Documentation](https://github.com/ggerganov/llama.cpp)

5. **Community support**:
   - OpenHands GitHub Issues
   - Ollama Discord
   - llama.cpp Discussions