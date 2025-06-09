# 🧠 Solace AI + Automation System

## 🔧 How to Start

1. Open PowerShell or Command Prompt.
2. Navigate to your project directory:
   ```powershell
   cd "%USERPROFILE%\OneDrive\Documents\ai_assistant_system"
   ```
3. Run the startup script:
   ```powershell
   start_all_services.bat
   ```

Or directly:
```powershell
docker-compose --env-file .env up -d --build
```

---

## 🌐 Service Access URLs

| Service             | URL                            | Notes                                |
|---------------------|----------------------------------|--------------------------------------|
| Solace Flask API    | http://localhost:5000           | Your assistant’s backend API         |
| Open WebUI          | http://localhost:3000           | Chat interface for LLMs              |
| Ollama API          | http://localhost:11434          | Local model host                     |
| HuggingFace TGI     | http://localhost:8080           | Falcon-7B hosted model               |
| ChromaDB            | http://localhost:8000           | Vector DB for memory                 |
| Redis               | localhost:6379                  | AI memory/session cache              |
| Jupyter Notebooks   | http://localhost:8888           | AI + Data Science                    |
| LibreTranslate      | http://localhost:5005           | Offline translation API              |
| MinIO Console       | http://localhost:9001           | S3-style storage (admin/changeme)    |
| Home Assistant      | http://localhost:8123           | Smart home hub                       |
| Node-RED            | http://localhost:1880           | Visual automation builder            |
| Mosquitto MQTT      | localhost:1883                  | IoT message broker                   |
| Portainer Dashboard | http://localhost:9000           | Docker container UI                  |
| NGINX Proxy Admin   | http://localhost:81             | Add domain or HTTPS easily           |
| Netdata Metrics     | http://localhost:19999          | Live system monitoring               |
| Vaultwarden (PM)    | http://localhost:8081           | Password manager                     |
| RustDesk (Relay)    | Ports 21115–21118               | Remote desktop support               |

---

## 🔐 Environment Variables (`.env`)

Edit `.env` to change passwords, secrets, and model names:
```
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=changeme
REDIS_PASSWORD=solaceSecure123
RUSTDESK_KEY=LtZDsX47bYhMVt+KBBu4InnMzibHPa0w5Qh1oXxq2rc=
TGI_MODEL=tiiuae/falcon-7b-instruct
```

---

## 📦 Preloaded Hugging Face Model

- `tiiuae/falcon-7b-instruct` (TGI)
- Can be changed via `.env` or in `docker-compose.yml`

---

## 🔄 To Stop Services

```bash
docker-compose down
```

To stop and delete volumes (use with caution):
```bash
docker-compose down -v
```

---

## 🧠 Next: Dataset and Memory Integration
You can connect:
- Hugging Face datasets for multilingual prompts
- ChromaDB to your AI API for persistent memory
- MinIO for audio/photo logging

Need help doing that? Just ask.
