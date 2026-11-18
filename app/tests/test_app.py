from app import app


def test_index_returns_greeting():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    body = response.get_json()
    assert "message" in body
    assert "hostname" in body


def test_healthz_is_ok():
    client = app.test_client()
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}