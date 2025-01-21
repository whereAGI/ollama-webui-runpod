# Ollama WebUI RunPod Template

This template provides a production-ready setup for running Ollama with Open WebUI and VS Code on RunPod. It's designed for both development and inference workloads.

## Features

- Ollama for running LLMs
- Open WebUI for chat interface
- VS Code for development
- GPU support
- Persistent storage
- Automatic service recovery

## Quick Start

1. Build and push the custom image (one-time setup):
```bash
docker build -t your-dockerhub-username/ollama-webui:latest .
docker push your-dockerhub-username/ollama-webui:latest
```

2. Create a new Pod on RunPod with these settings:

```
Container Image: your-dockerhub-username/ollama-webui:latest

Expose Ports:
- HTTP 3000 (WebUI)
- HTTP 8080 (VS Code)
- TCP 11434 (Ollama API)

Environment Variables:
- NVIDIA_VISIBLE_DEVICES=all
- PASSWORD=your_vscode_password

Volume Mount:
- Container Path: /root/.ollama
  Size: 20GB (or more depending on your models)
```

3. Access your services:
- WebUI: https://<pod-id>-3000.proxy.runpod.net
- VS Code: https://<pod-id>-8080.proxy.runpod.net
- Ollama API: https://<pod-id>-11434.proxy.runpod.net

## Development

- The `/root/workspace` directory is persistent and mounted in VS Code
- Use VS Code's terminal to manage Ollama models and configurations
- Access GPU resources through Ollama's API

## Model Management

To download and run models:

```bash
# List available models
ollama list

# Pull a model
ollama pull llama2

# Run a model
ollama run llama2
```

## Troubleshooting

If services don't start properly:

1. Check container logs:
```bash
docker logs open-webui
docker logs code-server
```

2. Verify Ollama is running:
```bash
curl localhost:11434/api/version
```

3. Restart services if needed:
```bash
docker restart open-webui
docker restart code-server
```

## Contributing

Feel free to open issues or submit pull requests for improvements.

## License

MIT License