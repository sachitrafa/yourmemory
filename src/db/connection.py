"""
Database connection factory.

Auto-detects backend from DATABASE_URL:
  postgresql:// or postgres://  → PostgreSQL + pgvector
  sqlite:///path                → SQLite at given path
  (unset / anything else)       → SQLite at ~/.yourmemory/memories.db  (default)

Usage:
    from src.db.connection import get_conn, get_backend

    conn = get_conn()    # works for both backends
    backend = get_backend()   # "sqlite" or "postgres"
"""

import os
import sqlite3
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()


def get_backend() -> str:
    """Return 'sqlite' or 'postgres' based on DATABASE_URL."""
    url = os.getenv("DATABASE_URL", "")
    if url.startswith("postgresql://") or url.startswith("postgres://"):
        return "postgres"
    return "sqlite"


def _sqlite_path() -> str:
    """Resolve the SQLite file path."""
    url = os.getenv("DATABASE_URL", "")
    if url.startswith("sqlite:///"):
        return url[10:]
    path = Path.home() / ".yourmemory" / "memories.db"
    path.parent.mkdir(parents=True, exist_ok=True)
    return str(path)


def get_conn():
    """Return an open database connection for the configured backend."""
    if get_backend() == "postgres":
        import psycopg2
        return psycopg2.connect(os.getenv("DATABASE_URL"))
    path = _sqlite_path()
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def emb_to_db(embedding: list, backend: str = None) -> str:
    """
    Serialize an embedding list for storage.
      Postgres: '[0.1,0.2,...]'  (pgvector wire format)
      SQLite:   JSON string      (stored as TEXT)
    """
    import json
    if (backend or get_backend()) == "postgres":
        return f"[{','.join(str(x) for x in embedding)}]"
    return json.dumps(embedding)
