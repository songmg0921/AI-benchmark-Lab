from fastapi.testclient import TestClient
from app.main import app
client = TestClient(app)
def test_health(): assert client.get('/api/health').status_code == 200
def test_ping(): assert client.get('/api/network/ping').json()['ok'] is True
def test_download_limit(): assert client.get('/api/network/download?size=1024').status_code == 200
def test_upload_limit(): assert client.post('/api/network/upload', content=b'abc').json()['bytes'] == 3
def test_reject_large_download(): assert client.get('/api/network/download?size=99999999').status_code == 400
