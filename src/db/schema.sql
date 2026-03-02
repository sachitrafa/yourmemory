CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS memories (
    id               SERIAL PRIMARY KEY,
    user_id          TEXT NOT NULL,
    content          TEXT NOT NULL,
    memory_type      TEXT NOT NULL DEFAULT 'trivial',
    importance       FLOAT NOT NULL DEFAULT 0.5,
    recall_count     INTEGER NOT NULL DEFAULT 0,
    last_accessed_at TIMESTAMP DEFAULT NOW(),
    created_at       TIMESTAMP DEFAULT NOW(),
    category         TEXT NOT NULL DEFAULT 'fact',
    embedding        vector(768),
    UNIQUE (user_id, content)
);

-- ivfflat index is only useful at scale (10k+ rows).
-- For small datasets, PostgreSQL does an exact scan automatically.
-- Uncomment when you have enough data:
-- CREATE INDEX IF NOT EXISTS memories_embedding_idx
--     ON memories USING ivfflat (embedding vector_cosine_ops)
--     WITH (lists = 100);

CREATE INDEX IF NOT EXISTS memories_user_id_idx ON memories (user_id);
