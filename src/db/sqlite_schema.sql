-- YourMemory SQLite schema (zero-setup default backend)
-- Embeddings stored as JSON TEXT; cosine similarity computed in Python.

CREATE TABLE IF NOT EXISTS memories (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id          TEXT NOT NULL,
    content          TEXT NOT NULL,
    memory_type      TEXT NOT NULL DEFAULT 'trivial',
    importance       REAL NOT NULL DEFAULT 0.5,
    recall_count     INTEGER NOT NULL DEFAULT 0,
    last_accessed_at TEXT DEFAULT (datetime('now')),
    created_at       TEXT DEFAULT (datetime('now')),
    category         TEXT NOT NULL DEFAULT 'fact',
    agent_id         TEXT NOT NULL DEFAULT 'user',
    visibility       TEXT NOT NULL DEFAULT 'shared',
    embedding        TEXT,    -- JSON array of floats (768 dims)
    UNIQUE (user_id, content)
);

CREATE INDEX IF NOT EXISTS memories_user_id_idx ON memories (user_id);
CREATE INDEX IF NOT EXISTS memories_agent_id_idx ON memories (agent_id);

-- Agent registrations — API key auth for multi-agent systems
-- can_read / can_write stored as JSON arrays (TEXT) instead of Postgres TEXT[]
CREATE TABLE IF NOT EXISTS agent_registrations (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id     TEXT UNIQUE NOT NULL,
    user_id      TEXT NOT NULL,
    api_key_hash TEXT UNIQUE NOT NULL,
    can_read     TEXT DEFAULT '[]',
    can_write    TEXT DEFAULT '["shared", "private"]',
    description  TEXT DEFAULT '',
    created_at   TEXT DEFAULT (datetime('now')),
    revoked_at   TEXT    -- NULL = active
);

CREATE INDEX IF NOT EXISTS agent_reg_user_id_idx ON agent_registrations (user_id);
CREATE INDEX IF NOT EXISTS agent_reg_api_key_idx ON agent_registrations (api_key_hash);
