from fastapi import FastAPI
from src.routes import memories, retrieve

app = FastAPI(title="YourMemory", version="0.1.0")

app.include_router(memories.router)
app.include_router(retrieve.router)


@app.get("/health")
def health():
    return {"status": "ok"}
