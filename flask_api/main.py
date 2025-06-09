# flask_api/main.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "Solace Flask API running!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
