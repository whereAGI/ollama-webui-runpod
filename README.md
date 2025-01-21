# Ollama WebUI RunPod Template

This template provides a setup for running Ollama with Open WebUI and VS Code on RunPod.

## Quick Start

Create a new Pod on RunPod with these settings:

```
Container Image: nvidia/cuda:12.1.0-base-ubuntu22.04

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

Start Command:
/bin/bash -c 'apt-get update && apt-get install -y curl docker.io && curl -L https://raw.githubusercontent.com/whereAGI/ollama-webui-runpod/main/start.sh -o start.sh && chmod +x start.sh && ./start.sh'
```

## Access

After the pod starts, you can access:
- WebUI: https://<pod-id>-3000.proxy.runpod.net
- VS Code: https://<pod-id>-8080.proxy.runpod.net
- Ollama API: https://<pod-id>-11434.proxy.runpod.net

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