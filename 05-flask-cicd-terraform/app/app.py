"""A small but real URL shortener with Prometheus instrumentation.

Endpoints:
  GET  /              - HTML form to shorten a URL
  POST /api/shorten   - {"url": "..."} -> {"code", "short_url"}
  GET  /<code>        - 302 redirect to the original URL
  GET  /healthz       - liveness/readiness probe
  GET  /metrics       - Prometheus exposition
"""
import os
import random
import string
import time

from flask import (
    Flask,
    abort,
    jsonify,
    redirect,
    render_template_string,
    request,
)
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

ALPHABET = string.ascii_letters + string.digits
CODE_LEN = int(os.environ.get("CODE_LEN", "6"))

app = Flask(__name__)

# In-memory store. Single-replica by design; a production deploy would back this
# with Redis/Postgres (documented in the README).
_store: dict[str, str] = {}

SHORTEN_TOTAL = Counter("urlshort_shorten_total", "URLs shortened")
REDIRECT_TOTAL = Counter("urlshort_redirect_total", "Redirects served")
REQUEST_LATENCY = Histogram(
    "urlshort_request_latency_seconds", "Request latency", ["method", "endpoint"]
)

INDEX_HTML = """<!doctype html>
<title>URL Shortener</title>
<style>body{font-family:system-ui;max-width:40rem;margin:6vh auto;padding:0 1rem}
input{width:100%;padding:.6rem;font-size:1rem}button{padding:.6rem 1rem;margin-top:.6rem}
code{background:#eef;padding:.2rem .4rem;border-radius:4px}</style>
<h1>🔗 URL Shortener</h1>
<form onsubmit="event.preventDefault();shorten()">
  <input id="u" placeholder="https://example.com/very/long/link" required>
  <button>Shorten</button>
</form>
<p id="out"></p>
<script>
async function shorten(){
  const u=document.getElementById('u').value;
  const r=await fetch('/api/shorten',{method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify({url:u})});
  const j=await r.json();
  document.getElementById('out').innerHTML = r.ok
    ? 'Short URL: <a href="'+j.short_url+'"><code>'+j.short_url+'</code></a>'
    : 'Error: '+j.error;
}
</script>
"""


def _gen_code() -> str:
    while True:
        code = "".join(random.choices(ALPHABET, k=CODE_LEN))
        if code not in _store:
            return code


@app.before_request
def _start_timer() -> None:
    request._start = time.perf_counter()  # type: ignore[attr-defined]


@app.after_request
def _record_latency(response):
    start = getattr(request, "_start", None)
    if start is not None:
        REQUEST_LATENCY.labels(request.method, request.endpoint or "unknown").observe(
            time.perf_counter() - start
        )
    return response


@app.get("/")
def index():
    return render_template_string(INDEX_HTML)


@app.post("/api/shorten")
def shorten():
    data = request.get_json(silent=True) or request.form
    url = (data.get("url") or "").strip()
    if not (url.startswith("http://") or url.startswith("https://")):
        return jsonify(error="url must start with http:// or https://"), 400
    code = _gen_code()
    _store[code] = url
    SHORTEN_TOTAL.inc()
    short_url = request.host_url.rstrip("/") + "/" + code
    return jsonify(code=code, short_url=short_url, url=url), 201


@app.get("/healthz")
def healthz():
    return jsonify(status="ok"), 200


@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.get("/<code>")
def follow(code: str):
    url = _store.get(code)
    if not url:
        abort(404)
    REDIRECT_TOTAL.inc()
    return redirect(url, code=302)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
