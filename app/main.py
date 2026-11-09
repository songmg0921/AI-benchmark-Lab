from pathlib import Path
import os
import secrets
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import FileResponse, Response
from fastapi.staticfiles import StaticFiles

BASE = Path(__file__).resolve().parent.parent
app = FastAPI(title="AI Benchmark Lab", version="0.1.0")

@app.get("/api/health")
def health():
    return {"status": "ok", "service": "ai-benchmark-lab", "version": os.getenv("APP_VERSION", app.version)}

@app.get("/api/version")
def version():
    return {"service": "ai-benchmark-lab", "version": os.getenv("APP_VERSION", app.version)}

@app.get("/api/network/ping")
def ping():
    return {"ok": True, "nonce": secrets.token_hex(8), "server_time_ms": __import__('time').time_ns() / 1_000_000}

@app.get("/api/network/download")
def download(size: int = 262144):
    if size < 1024 or size > 2 * 1024 * 1024:
        raise HTTPException(400, "size must be between 1024 and 2097152 bytes")
    data = bytes((i * 31) % 251 for i in range(size))
    return Response(data, media_type="application/octet-stream", headers={"Cache-Control":"no-store", "Content-Length":str(size)})

@app.post("/api/network/upload")
async def upload(request: Request):
    body = await request.body()
    if len(body) > 2 * 1024 * 1024:
        raise HTTPException(413, "payload too large")
    return {"ok": True, "bytes": len(body)}

app.mount("/static", StaticFiles(directory=BASE / "frontend"), name="static")

@app.get("/")
def index():
    return FileResponse(BASE / "frontend" / "index.html")
