version: '3.8'

services:
  flask-api:
    build:
      context: ./flask_api
    ports:
      - "${FLASK_PORT}:${FLASK_PORT}"  # e.g., 3000:3000
    env_file:
      - .env
    volumes:
      - ./flask_api:/app
      - ./data:/app/data
    depends_on:
      - whisper
      - ollama
    profiles: [core]

  whisper:
    image: ghcr.io/ggerganov/whisper.cpp:main
    container_name: whisper-gpu
    runtime: nvidia
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
    volumes:
      - ./input_audio:/input
      - ./output_text:/output
      - ./models:/models
    command: ["./main", "-m", "/models/ggml-base.en.bin", "-f", "/input/audio.wav", "-otxt", "-of", "/output/transcription"]
    # 🔹 No port needed — this runs batch processing

  ollama:
    image: ollama/ollama
    volumes:
      - ollama_data:/root/.ollama
    env_file:
      - .env
    ports:
      - "11434:11434"  # Default Ollama API port
    profiles: [core]

open-webui:
  image: ghcr.io/open-webui/open-webui:main
  depends_on:
    - ollama
  env_file:
    - .env
  volumes:
    - openwebui_data:/app/backend/data
  ports:
    - "3000:8080"  # ✅ Only one "ports" here
  profiles: [core]

solace-webui:
  build:
    context: ./solace-webui
  container_name: ai_assistant_system-solace-webui
  ports:
    - "5173:3000"  # ✅ Just this one
  profiles: [frontend]
  environment:
    - OLLAMA_API_BASE_URL=http://ollama:11434
  depends_on:
    - ollama

  tgi:
    image: ghcr.io/huggingface/text-generation-inference:latest
    env_file:
      - .env
    environment:
      - MODEL_ID=${TGI_MODEL}
      - DISABLE_CUSTOM_MODEL=false
      - QUANTIZE=bitsandbytes
    volumes:
      - ./tgi_models:/data/tgi_models
    runtime: nvidia
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
    ports:
      - "8081:80"  # Access the TGI server on port 8081
    profiles: [ai]

  tgi-switcher:
    build:
      context: ./tgi-switcher
    env_file:
      - .env
    ports:
      - "5005:5005"  # Switcher internal routing
    profiles: [ai]

  redis:
    image: redis:alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    ports:
      - "6379:6379"  # Redis client access
    profiles: [support]

  minio:
    image: minio/minio
    command: server /data
    env_file:
      - .env
    ports:
      - "9000:9000"  # MinIO access
    volumes:
      - minio_data:/data
    profiles: [support]

  gpu-monitor:
    image: nvidia/cuda:12.3.2-base-ubuntu22.04
    container_name: gpu-monitor
    runtime: nvidia
    volumes:
      - ./logs/gpu:/logs
    command: ["/bin/sh", "-c", "while true; do nvidia-smi >> /logs/usage.log; sleep 5; done"]
    profiles: [support]
    # 🔹 No exposed port — logs written to shared volume

  tailscale:
    image: tailscale/tailscale
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
    volumes:
      - tailscale_data:/var/lib/tailscale
    cap_add:
      - NET_ADMIN
    network_mode: host
    profiles: [optional]
    # ⚠️ Host mode used — handles its own ports

  portainer:
    image: portainer/portainer-ce
    volumes:
      - portainer_data:/data
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "9001:9000"  # Access Portainer via http://localhost:9001
    profiles: [optional]

volumes:
  ollama_data:
  openwebui_data:
  portainer_data:
  tailscale_data:
  minio_data:
  tgi_models:
