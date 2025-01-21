#!/bin/bash

# Start Docker daemon
dockerd > /var/log/dockerd.log 2>&1 &

# Function to check if Docker daemon is ready
wait_for_docker() {
    local max_attempts=30
    local attempt=1
    echo "Waiting for Docker daemon to start..."
    while ! docker info >/dev/null 2>&1; do
        if [ $attempt -gt $max_attempts ]; then
            echo "Docker daemon failed to start in time"
            return 1
        fi
        echo "Attempt $attempt/$max_attempts: Docker daemon not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done
    echo "Docker daemon is ready!"
    return 0
}

# Start Ollama
ollama serve &

# Wait for Docker to be ready
wait_for_docker || exit 1

echo "Starting Open WebUI..."
docker run -d \
    --network host \
    -e OLLAMA_API_BASE_URL=http://localhost:11434 \
    -v open-webui:/app/backend/data \
    --name open-webui \
    --restart always \
    ghcr.io/open-webui/open-webui:main

echo "Starting VS Code server..."
docker run -d \
    --network host \
    -v /root/workspace:/root/workspace \
    -e PASSWORD=${PASSWORD:-password} \
    --name code-server \
    --restart always \
    codercom/code-server:latest \
    --bind-addr 0.0.0.0:8080

# Keep the script running and monitor services
while true; do
    sleep 30
    # Check if all services are running
    if ! docker ps | grep -q open-webui; then
        echo "Open WebUI container is not running, attempting to restart..."
        docker start open-webui
    fi
    if ! docker ps | grep -q code-server; then
        echo "VS Code server container is not running, attempting to restart..."
        docker start code-server
    fi
    if ! pgrep ollama > /dev/null; then
        echo "Ollama is not running, attempting to restart..."
        ollama serve &
    fi
done