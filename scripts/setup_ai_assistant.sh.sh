#!/bin/bash
echo "==== AI Assistant System Status Check ===="

uname -a
nvidia-smi || echo "❗ NVIDIA GPU not detected or drivers missing."

check_command() {
    if command -v $1 &> /dev/null; then
        echo "✔ $2 Found"
    else
        echo "❌ $2 NOT Found"
    fi
}

check_command docker "Docker"
check_command ollama "Ollama"
check_command ffmpeg "FFmpeg"
check_command jq "jq"
check_command iperf3 "iperf3"
check_command curl "curl"
check_command tailscale "Tailscale"

echo -e "\\n--- Python Modules ---"
source ~/whisper_env/bin/activate
python3 -c "import whisper" && echo "✔ Whisper (Python) Found" || echo "❌ Whisper (Python) NOT Found"
python3 -c "import flask" && echo "✔ Flask Found" || echo "❌ Flask NOT Found"
python3 -c "import fastapi" && echo "✔ FastAPI Found" || echo "❌ FastAPI NOT Found"
python3 -c "import cv2" && echo "✔ OpenCV Found" || echo "❌ OpenCV NOT Found"
python3 -c "import face_recognition" && echo "✔ face_recognition Found" || echo "❌ face_recognition NOT Found"

if [ -f ~/whisper.cpp/build/bin/whisper-cli ]; then
    echo "✔ Whisper.cpp Found at ~/whisper.cpp/build/bin/whisper-cli"
else
    echo "❌ Whisper.cpp NOT Found"
fi

if [ -x ~/piper ]; then
    echo "✔ Piper Binary Found"
else
    echo "❌ Piper Binary NOT Found"
fi

echo -e "\\n--- Ollama Models Installed ---"
models=(llama3:8b mistral openhermes)
for model in "${models[@]}"; do
    if ollama list | grep -q "$model"; then
        echo "✔ Model '$model' is installed"
    else
        echo "❌ Model '$model' is MISSING - Run: ollama pull $model"
    fi
done

echo "==== Status Check Complete ===="
