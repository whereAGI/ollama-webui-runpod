FROM nvidia/cuda:12.1.0-base-ubuntu22.04

# Install essential packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    docker.io \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Copy start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose ports
EXPOSE 11434 3000 8080

# Start services
ENTRYPOINT ["/start.sh"]