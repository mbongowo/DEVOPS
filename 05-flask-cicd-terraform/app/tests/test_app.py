import pytest

from app.app import app as flask_app


@pytest.fixture()
def client():
    flask_app.testing = True
    return flask_app.test_client()


def test_health(client):
    r = client.get("/healthz")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"


def test_shorten_and_redirect(client):
    r = client.post("/api/shorten", json={"url": "https://example.com/page"})
    assert r.status_code == 201
    body = r.get_json()
    assert len(body["code"]) == 6
    assert body["short_url"].endswith(body["code"])

    follow = client.get(f"/{body['code']}")
    assert follow.status_code == 302
    assert follow.headers["Location"] == "https://example.com/page"


def test_rejects_non_http_url(client):
    r = client.post("/api/shorten", json={"url": "ftp://nope"})
    assert r.status_code == 400
    assert "error" in r.get_json()


def test_unknown_code_returns_404(client):
    assert client.get("/zzzzzz").status_code == 404


def test_metrics_exposes_counters(client):
    client.post("/api/shorten", json={"url": "https://a.example"})
    r = client.get("/metrics")
    assert r.status_code == 200
    assert b"urlshort_shorten_total" in r.data
    assert b"urlshort_request_latency_seconds" in r.data
