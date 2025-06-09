from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "Solace Flask API is running."

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("FLASK_PORT", 3050)))

