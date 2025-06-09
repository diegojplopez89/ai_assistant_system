import os
import json
import threading
import requests
import subprocess
import tempfile
import uuid
import logging

from flask import Flask, request, jsonify, send_file
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# --- Configuration ---
FLASK_HOST = os.getenv("FLASK_HOST", "0.0.0.0")
FLASK_PORT = int(os.getenv("FLASK_PORT", 5000))
FLASK_DEBUG = os.getenv("FLASK_DEBUG", "True").lower() == "true"
ESP32_IP = os.getenv("ESP32_IP", "http://192.168.86.42")
OLLAMA_API_URL = os.getenv("OLLAMA_API_URL", "http://localhost:11434/api/chat")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3:8b")
OLLAMA_SYSTEM_PROMPT = os.getenv("OLLAMA_SYSTEM_PROMPT", "You are Solace, a compassionate and intelligent field assistant helping with humanitarian work.")
WHISPER_MODEL_NAME = os.getenv("WHISPER_MODEL_NAME", "base")
PIPER_COMMAND = os.getenv("PIPER_COMMAND", "piper")
PIPER_MODEL = os.getenv("PIPER_MODEL", "en_US-lessac-medium")
DATA_DIR = os.getenv("DATA_DIR", "./data")
FFMPEG_CUSTOM_PATH = os.getenv("FFMPEG_CUSTOM_PATH", "")
GREET_ON_START = os.getenv("GREET_ON_START", "True").lower() == "true"
PLAY_AUDIO_ON_SERVER = os.getenv("PLAY_AUDIO_ON_SERVER", "True").lower() == "true"
HOTWORD = os.getenv("HOTWORD", "solace").lower()
DATA_AUDIO_PATH = os.path.join(DATA_DIR, "audio")

# Ensure paths exist
os.makedirs(DATA_AUDIO_PATH, exist_ok=True)
if FFMPEG_CUSTOM_PATH and FFMPEG_CUSTOM_PATH not in os.environ["PATH"]:
    os.environ["PATH"] += os.pathsep + FFMPEG_CUSTOM_PATH

# Logging setup
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load Whisper model
try:
    import whisper
    whisper_model = whisper.load_model(WHISPER_MODEL_NAME)
    logger.info(f"Whisper model '{WHISPER_MODEL_NAME}' loaded.")
except Exception as e:
    logger.error(f"Failed to load Whisper model: {e}")
    whisper_model = None

app = Flask(__name__)

def ask_ollama(question):
    try:
        response = requests.post(
            OLLAMA_API_URL,
            json={
                "model": OLLAMA_MODEL,
                "messages": [
                    {"role": "system", "content": OLLAMA_SYSTEM_PROMPT},
                    {"role": "user", "content": question}
                ],
                "stream": True
            },
            stream=True,
            timeout=120
        )
        response.raise_for_status()
        full_response = ""
        for line in response.iter_lines():
            if line:
                try:
                    chunk = json.loads(line.decode('utf-8'))
                    if "message" in chunk and "content" in chunk["message"]:
                        full_response += chunk["message"]["content"]
                except json.JSONDecodeError:
                    continue
        return True, full_response.strip()
    except Exception as e:
        logger.error(f"Ollama error: {e}")
        return False, str(e)

def play_audio_file(path):
    if not PLAY_AUDIO_ON_SERVER:
        return
    try:
        if os.name == 'nt':
            subprocess.Popen(['cmd', '/c', 'start', '', '/b', path], shell=True)
        else:
            subprocess.run(['xdg-open', path])
    except Exception as e:
        logger.error(f"Playback error: {e}")

def greet_on_start():
    if not GREET_ON_START:
        return
    greeting = "Hello Diego, I’m Solace. I’m ready to help."
    path = os.path.join(DATA_AUDIO_PATH, "greet.wav")
    try:
        process = subprocess.Popen([
            PIPER_COMMAND,
            "--model", PIPER_MODEL,
            "--output_file", path
        ], stdin=subprocess.PIPE)
        process.communicate(input=greeting.encode())
        play_audio_file(path)
    except Exception as e:
        logger.error(f"Greeting error: {e}")

@app.route("/")
def home():
    return "✅ Solace AI Assistant API is running."

@app.route("/ask", methods=["POST"])
def ask():
    data = request.get_json()
    question = data.get("question", "")
    success, answer = ask_ollama(question)
    return jsonify({"response": answer}) if success else (jsonify({"error": answer}), 500)

@app.route("/transcribe", methods=["POST"])
def transcribe():
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400
    if not whisper_model:
        return jsonify({'error': 'Whisper model not loaded'}), 500
    file = request.files['audio']
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav", dir=DATA_AUDIO_PATH) as tmp:
            file.save(tmp.name)
            result = whisper_model.transcribe(tmp.name)
        return jsonify({"transcription": result["text"]})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/voice_query", methods=["POST"])
def voice_query():
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400
    file = request.files['audio']
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav", dir=DATA_AUDIO_PATH) as tmp:
            file.save(tmp.name)
            text = whisper_model.transcribe(tmp.name)["text"].strip()
            if not text.lower().startswith(HOTWORD):
                return jsonify({"transcription": text, "error": f"Hotword '{HOTWORD}' not detected."}), 403
            prompt = text[len(HOTWORD):].strip(" ,:.")
            success, response = ask_ollama(prompt)
            if not success:
                return jsonify({"error": response}), 500
            followup_prompt = f"What are 3 helpful follow-up questions to this response: {response}"
            _, follow_ups = ask_ollama(followup_prompt)
            return jsonify({"transcription": text, "prompt": prompt, "response": response, "follow_ups": follow_ups})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/speak", methods=["POST"])
def speak():
    data = request.get_json()
    text = data.get("text", "")
    if not text:
        return jsonify({"error": "No text provided"}), 400
    output = os.path.join(DATA_AUDIO_PATH, f"response_{uuid.uuid4().hex}.wav")
    try:
        process = subprocess.Popen([
            PIPER_COMMAND,
            "--model", PIPER_MODEL,
            "--output_file", output
        ], stdin=subprocess.PIPE)
        process.communicate(input=text.encode())
        play_audio_file(output)
        return jsonify({"message": "Speech generated.", "audio_file": output})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/get_audio/<filename>")
def get_audio(filename):
    path = os.path.join(DATA_AUDIO_PATH, filename)
    return send_file(path, mimetype="audio/wav") if os.path.exists(path) else (jsonify({"error": "File not found."}), 404)

@app.route("/trigger/<action>", methods=["POST"])
def trigger(action):
    endpoint_map = {
        "audio": "record_audio",
        "photo": "capture_photo"
    }
    if action not in endpoint_map:
        return jsonify({"error": "Invalid action"}), 400
    try:
        r = requests.get(f"{ESP32_IP}/{endpoint_map[action]}", timeout=10)
        return jsonify({"status": "triggered", "response": r.text})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    if GREET_ON_START:
        threading.Thread(target=greet_on_start, daemon=True).start()
    if FLASK_DEBUG:
        app.run(host=FLASK_HOST, port=FLASK_PORT, debug=True)
    else:
        from waitress import serve
        serve(app, host=FLASK_HOST, port=FLASK_PORT)