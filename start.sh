#!/bin/bash

# Start Docker daemon
dockerd &

# Wait for Docker daemon to be ready
echo "Waiting for Docker daemon..."
while ! docker info > /dev/null 2>&1; do
    sleep 2
done

# Start Ollama
echo "Starting Ollama..."
ollama serve --host 0.0.0.0 &
sleep 5

# Start Open WebUI
echo "Starting Open WebUI..."
docker run -d \
    --network host \
    -e OLLAMA_API_BASE_URL=http://0.0.0.0:11434 \
    --name open-webui \
    ghcr.io/open-webui/open-webui:main

# Start VS Code server
echo "Starting VS Code server..."
docker run -d \
    --network host \
    -v /root/workspace:/root/workspace \
    -e PASSWORD=${PASSWORD:-password} \
    --name code-server \
    codercom/code-server:latest \
    --bind-addr 0.0.0.0:8080 \
    --auth password

# Keep the script running and monitor services
while true; do
    sleep 10
    if ! pgrep ollama > /dev/null; then
        echo "Restarting Ollama..."
        ollama serve --host 0.0.0.0 &
    fi
done