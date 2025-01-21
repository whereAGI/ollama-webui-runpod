#!/bin/bash

# Enable error handling
set -e

# Function to check if a port is in use
port_in_use() {
    nc -z localhost $1 >/dev/null 2>&1
}

# Wait for port to be available
wait_for_port() {
    local port=$1
    local service=$2
    local retries=30
    while port_in_use $port; do
        retries=$((retries-1))
        if [ $retries -eq 0 ]; then
            echo "Error: Port $port for $service is still in use after waiting"
            exit 1
        fi
        echo "Waiting for port $port to be available for $service..."
        sleep 1
    done
}

# Create workspace directory if it doesn't exist
mkdir -p /root/workspace

# Start Ollama
echo "Starting Ollama..."
wait_for_port 11434 "Ollama"
ollama serve &

# Wait for Ollama to start
sleep 5

# Start Open WebUI
echo "Starting Open WebUI..."
wait_for_port 3000 "WebUI"
docker run -d \
    --network host \
    -e OLLAMA_API_BASE_URL=http://localhost:11434 \
    -v open-webui:/app/backend/data \
    --name open-webui \
    --restart always \
    ghcr.io/open-webui/open-webui:main

# Start code-server
echo "Starting VS Code Server..."
wait_for_port 8080 "VS Code"
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