import json
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/generate-map", methods=["POST"])
def generate_map():
    # Return a plausible test map response
    response = {
        "surface": {
            "type": "forest",
            "segments": [
                {"type": "plains", "length": 300},
                {"type": "forest", "length": 100},
                {"type": "mountains", "length": 80}
            ]
        },
        "underground": {
            "type": "caves",
            "tunnels": 1,
            "room_shape": "organic"
        }
    }
    return jsonify(response)

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000)
