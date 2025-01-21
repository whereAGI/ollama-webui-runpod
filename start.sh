#!/bin/bash

# Start Docker daemon
dockerd &

# Wait for Docker to be ready
echo "Waiting for Docker daemon..."
while ! docker info >/dev/null 2>&1; do
    sleep 2
done
echo "Docker daemon is ready"

# Start Ollama on all interfaces
echo "Starting Ollama..."
ollama serve --host 0.0.0.0 &

# Wait for Ollama to be ready
echo "Waiting for Ollama to be ready..."
while ! curl -s http://0.0.0.0:11434/api/version >/dev/null; do
    sleep 2
done
echo "Ollama is ready"

# Create workspace directory
mkdir -p /root/workspace

# Start Open WebUI
echo "Starting Open WebUI..."
docker run -d \
    -p 3000:8080 \
    -e OLLAMA_API_BASE_URL=http://host.docker.internal:11434 \
    --add-host=host.docker.internal:host-gateway \
    -v open-webui:/app/backend/data \
    --name open-webui \
    --restart always \
    ghcr.io/open-webui/open-webui:main

# Start VS Code server
echo "Starting VS Code server..."
docker run -d \
    -p 8080:8080 \
    -v /root/workspace:/root/workspace \
    -e PASSWORD=${PASSWORD:-password} \
    --name code-server \
    --restart always \
    codercom/code-server:latest \
    --bind-addr 0.0.0.0:8080 \
    --auth password

echo "All services started!"

# Monitor and maintain services
while true; do
    sleep 30
    
    # Check Ollama
    if ! curl -s http://0.0.0.0:11434/api/version >/dev/null; then
        echo "Ollama is not responding, restarting..."
        pkill ollama
        ollama serve --host 0.0.0.0 &
    fi
    
    # Check Open WebUI
    if ! docker ps | grep -q open-webui; then
        echo "Open WebUI container is not running, restarting..."
        docker restart open-webui
    fi
    
    # Check VS Code
    if ! docker ps | grep -q code-server; then
        echo "VS Code container is not running, restarting..."
        docker restart code-server
    fi
done