#!/bin/bash

# Start Ollama
echo "Starting Ollama..."
ollama serve &

# Wait for Ollama to be ready
echo "Waiting for Ollama to be ready..."
MAX_RETRIES=30
count=0
while ! curl -s localhost:11434/api/version > /dev/null; do
    sleep 1
    count=$((count + 1))
    if [ $count -eq $MAX_RETRIES ]; then
        echo "Failed to start Ollama"
        exit 1
    fi
done
echo "Ollama is ready!"

# Configure container runtime
echo "Setting up container runtime..."
mkdir -p /etc/containerd
cat > /etc/containerd/config.toml << EOF
version = 2

[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "k8s.gcr.io/pause:3.2"

[plugins."io.containerd.grpc.v1.cri".containerd]
  default_runtime_name = "runc"

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
EOF

# Start containerd
echo "Starting containerd..."
containerd > /var/log/containerd.log 2>&1 &

# Wait for containerd to be ready
sleep 5

# Start Open WebUI using nerdctl (containerd-compatible Docker alternative)
echo "Starting Open WebUI..."
nerdctl run -d \
    --network host \
    -e OLLAMA_API_BASE_URL=http://localhost:11434 \
    -v open-webui:/app/backend/data \
    --name open-webui \
    --restart always \
    ghcr.io/open-webui/open-webui:main

# Start VS Code server
echo "Starting VS Code server..."
nerdctl run -d \
    --network host \
    -v /root/workspace:/root/workspace \
    -e PASSWORD=${PASSWORD:-password} \
    --name code-server \
    --restart always \
    codercom/code-server:latest \
    --bind-addr 0.0.0.0:8080

echo "All services started!"

# Monitor services
while true; do
    sleep 30
    if ! pgrep ollama > /dev/null; then
        echo "Ollama is not running, attempting to restart..."
        ollama serve &
    fi
    if ! pgrep containerd > /dev/null; then
        echo "containerd is not running, attempting to restart..."
        containerd > /var/log/containerd.log 2>&1 &
    fi
done