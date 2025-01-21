#!/bin/sh

# Create workspace directory if it doesn't exist
mkdir -p /root/workspace

# Start Ollama
echo "Starting Ollama..."
ollama serve &

# Wait for Ollama to start
sleep 5

# Start Open WebUI
echo "Starting Open WebUI..."
docker run -d \
    --network host \
    -e OLLAMA_API_BASE_URL=http://localhost:11434 \
    -v open-webui:/app/backend/data \
    --name open-webui \
    --restart always \
    ghcr.io/open-webui/open-webui:main

# Start code-server
echo "Starting VS Code Server..."
docker run -d \
    --network host \
    -v /root/workspace:/root/workspace \
    -e PASSWORD=${PASSWORD:-password} \
    --name code-server \
    --restart always \
    codercom/code-server:latest \
    --bind-addr 0.0.0.0:8080

# Keep the script running
tail -f /dev/null