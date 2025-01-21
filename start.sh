#!/bin/bash

# Start Ollama with explicit host binding
echo "Starting Ollama..."
ollama serve --host 0.0.0.0 &

# Wait for Ollama to be ready
echo "Waiting for Ollama to be ready..."
MAX_RETRIES=30
count=0
while ! curl -s http://0.0.0.0:11434/api/version > /dev/null; do
    sleep 1
    count=$((count + 1))
    if [ $count -eq $MAX_RETRIES ]; then
        echo "Failed to start Ollama"
        exit 1
    fi
done
echo "Ollama is ready!"

# Start Open WebUI directly with host network
echo "Starting Open WebUI..."
docker run -d \
    --network host \
    -e OLLAMA_API_BASE_URL=http://0.0.0.0:11434 \
    -e HOST=0.0.0.0 \
    -p 3000:8080 \
    -v open-webui:/app/backend/data \
    --name open-webui \
    --restart always \
    ghcr.io/open-webui/open-webui:main

# Start VS Code server with explicit host binding
echo "Starting VS Code server..."
docker run -d \
    --network host \
    -v /root/workspace:/root/workspace \
    -e PASSWORD=${PASSWORD:-password} \
    -p 8080:8080 \
    --name code-server \
    --restart always \
    codercom/code-server:latest \
    --bind-addr 0.0.0.0:8080 \
    --auth password

echo "All services started!"

# Print service URLs
echo "Service URLs:"
echo "Ollama API: http://0.0.0.0:11434"
echo "Open WebUI: http://0.0.0.0:3000"
echo "VS Code: http://0.0.0.0:8080"

# Keep script running
while true; do
    sleep 30
    # Check if services are running
    if ! curl -s http://0.0.0.0:11434/api/version > /dev/null; then
        echo "Ollama is not responding, attempting to restart..."
        ollama serve --host 0.0.0.0 &
    fi
    if ! curl -s http://0.0.0.0:3000 > /dev/null; then
        echo "Open WebUI is not responding, attempting to restart..."
        docker restart open-webui
    fi
    if ! curl -s http://0.0.0.0:8080 > /dev/null; then
        echo "VS Code server is not responding, attempting to restart..."
        docker restart code-server
    fi
done