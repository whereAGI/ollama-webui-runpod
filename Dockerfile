FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    docker.io \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl https://ollama.ai/install.sh | sh

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 11434 3000 8080

ENTRYPOINT ["/start.sh"]