import uvicorn
from src.db.migrate import migrate

if __name__ == "__main__":
    migrate()
    uvicorn.run("src.app:app", host="0.0.0.0", port=8000, reload=True)
