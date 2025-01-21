#!/bin/bash

# Initialize system services
mkdir -p /etc/systemd/system
cat > /etc/systemd/system/docker.service << 'EOF'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/dockerd
TimeoutStartSec=0
Restart=always
RuntimeDirectory=docker
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
EOF

# Start Docker in privileged mode
dockerd --privileged > /var/log/docker.log 2>&1 &

# Wait for Docker to be ready
echo "Waiting for Docker to start..."
while ! docker info > /dev/null 2>&1; do
    sleep 1
done
echo "Docker is ready."

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

echo "Setting up services..."

# Pull required images in advance
docker pull ghcr.io/open-webui/open-webui:main
docker pull codercom/code-server:latest

# Start Open WebUI
echo "Starting Open WebUI..."
docker run -d \
    --privileged \
    -p 3000:8080 \
    -e OLLAMA_API_BASE_URL=http://0.0.0.0:11434 \
    -v open-webui:/app/backend/data \
    --name open-webui \
    --restart always \
    ghcr.io/open-webui/open-webui:main

# Start VS Code server
echo "Starting VS Code server..."
docker run -d \
    --privileged \
    -p 8080:8080 \
    -v /root/workspace:/root/workspace \
    -e PASSWORD=${PASSWORD:-password} \
    --name code-server \
    --restart always \
    codercom/code-server:latest \
    --bind-addr 0.0.0.0:8080

echo "All services started!"

# Print service URLs
echo "Service URLs:"
echo "Ollama API: http://0.0.0.0:11434"
echo "Open WebUI: http://0.0.0.0:3000"
echo "VS Code: http://0.0.0.0:8080"

# Monitor services
while true; do
    sleep 30
    # Check if services are running
    if ! curl -s http://0.0.0.0:11434/api/version > /dev/null; then
        echo "Ollama is not responding, attempting to restart..."
        pkill ollama
        ollama serve --host 0.0.0.0 &
    fi
    if ! docker ps | grep -q open-webui; then
        echo "Open WebUI container is not running, attempting to restart..."
        docker restart open-webui
    fi
    if ! docker ps | grep -q code-server; then
        echo "VS Code container is not running, attempting to restart..."
        docker restart code-server
    fi
done