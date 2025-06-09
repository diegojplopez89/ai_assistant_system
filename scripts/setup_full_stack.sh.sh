#!/bin/bash
echo "📦 Setting up full AI Assistant structure..."

cd /mnt/c/Users/diego/OneDrive/Documents/ai_assistant_system || exit 1

mkdir -p api client config data/audio_samples data/transcripts logs models scripts tests

# Flask API
cat <<EOF > api/assistant_api.py
from flask import Flask, request, jsonify
import whisper
import ollama
import os

app = Flask(__name__)
whisper_model = whisper.load_model("base")

@app.route("/transcribe", methods=["POST"])
def transcribe():
    if 'audio' not in request.files:
        return jsonify({"error": "Missing audio file"}), 400
    audio = request.files['audio']
    filepath = f"/tmp/{audio.filename}"
    audio.save(filepath)
    try:
        result = whisper_model.transcribe(filepath)
        return jsonify({"text": result["text"]})
    finally:
        os.remove(filepath)

@app.route("/query", methods=["POST"])
def query():
    data = request.get_json()
    prompt = data.get("prompt")
    if not prompt:
        return jsonify({"error": "Missing prompt"}), 400
    response = ollama.chat(model="llama3:8b", messages=[{"role": "user", "content": prompt}])
    return jsonify({"response": response['message']['content']})

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
EOF

# Face Recognition Model
cat <<EOF > models/face_recognition.py
import face_recognition
import cv2

def detect_faces(image_path):
    image = face_recognition.load_image_file(image_path)
    face_locations = face_recognition.face_locations(image)
    print(f"Found {len(face_locations)} face(s) in this image.")
    return face_locations
EOF

# Video Capture Script
cat <<EOF > client/video_capture.py
import cv2

def capture_video():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Cannot access webcam")
        return

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        cv2.imshow('Video Feed', frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    capture_video()
EOF

# Test Transcription Script
cat <<EOF > scripts/test_transcribe.sh
#!/bin/bash
curl -X POST http://127.0.0.1:5000/transcribe \\
  -F "audio=@../data/audio_samples/sample.wav"
EOF

chmod +x scripts/test_transcribe.sh
touch README.md .gitignore requirements.txt docker-compose.yml
echo "Place audio samples here." > data/audio_samples/README.txt
echo "✅ AI Assistant structure set up successfully."
