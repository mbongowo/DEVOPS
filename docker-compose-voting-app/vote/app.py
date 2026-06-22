"""Voting front-end: cast a vote between two options, push it onto Redis."""
import json
import os
import socket
from flask import Flask, render_template, request, make_response, g

OPTION_A = os.environ.get("OPTION_A", "Cats")
OPTION_B = os.environ.get("OPTION_B", "Dogs")
REDIS_HOST = os.environ.get("REDIS_HOST", "redis")
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))
HOSTNAME = socket.gethostname()

app = Flask(__name__)


def get_redis():
    """Lazily create one Redis client per request context."""
    if not hasattr(g, "redis"):
        import redis

        g.redis = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0,
                              socket_connect_timeout=2)
    return g.redis


@app.route("/", methods=["GET", "POST"])
def index():
    # A stable per-browser id so re-votes overwrite rather than double-count.
    voter_id = request.cookies.get("voter_id") or os.urandom(8).hex()
    vote = None

    if request.method == "POST":
        vote = request.form["vote"]
        payload = json.dumps({"voter_id": voter_id, "vote": vote})
        get_redis().rpush("votes", payload)

    resp = make_response(render_template(
        "index.html",
        option_a=OPTION_A,
        option_b=OPTION_B,
        hostname=HOSTNAME,
        vote=vote,
    ))
    resp.set_cookie("voter_id", voter_id)
    return resp


@app.route("/healthz")
def healthz():
    return {"status": "ok"}, 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80, debug=True)
