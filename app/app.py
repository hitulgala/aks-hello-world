import os
import socket
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)

# Configuration comes from environment variables, with safe defaults.
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
GREETING = os.getenv("GREETING", "Hello, World! v2")


@app.get("/")
def index():
    return jsonify(
        message=GREETING,
        version=APP_VERSION,
        hostname=socket.gethostname(),
        time_utc=datetime.now(timezone.utc).isoformat(),
    )


@app.get("/healthz")
def healthz():
    return jsonify(status="ok")


if __name__ == "__main__":
    # Development server only. In the container we use gunicorn instead.
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)