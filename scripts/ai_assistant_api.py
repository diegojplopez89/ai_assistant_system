from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/transcribe", methods=["POST"])
def transcribe():
    audio_data = request.data
    if audio_data:
        print("Audio data received successfully")
        response = {
            "status": "received",
            "message": "Audio data received successfully",
            "length": len(audio_data)
        }
        return jsonify(response), 200
    else:
        return jsonify({"status": "error", "message": "No audio data"}), 400

# Update this with the actual IP address of your ESP32-S3 device
ESP32_IP = "http://172.28.224.1"  # You can also map this via Tailscale DNS

@app.route('/')
def index():
    return "✅ Solace AI Assistant Flask API is running."

@app.route('/trigger/audio', methods=['POST'])
def trigger_audio():
    """Trigger ESP32 to record audio and upload it."""
    try:
        r = requests.get(f"{ESP32_IP}/record_audio")
        return jsonify({"status": "triggered", "esp_response": r.text}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/trigger/photo', methods=['POST'])
def trigger_photo():
    """Trigger ESP32 to take a photo and upload it."""
    try:
        r = requests.get(f"{ESP32_IP}/capture_photo")
        return jsonify({"status": "triggered", "esp_response": r.text}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
