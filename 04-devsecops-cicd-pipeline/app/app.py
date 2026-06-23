"""Minimal Flask service used as the scan target for the DevSecOps pipeline."""
import os

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(service="devsecops-demo", env=os.environ.get("APP_ENV", "dev"))


@app.get("/healthz")
def healthz():
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    # Local dev only; the container serves via gunicorn bound to 0.0.0.0.
    app.run(host="127.0.0.1", port=8000)
