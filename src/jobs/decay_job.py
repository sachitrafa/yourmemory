"""
Run daily to update importance scores on all edges using the Ebbinghaus formula.
Edges that decay below a threshold are pruned automatically.

Usage:
    python -m src.jobs.decay_job

Or schedule via cron:
    0 2 * * * python /path/to/yourmemory -m src.jobs.decay_job
"""

import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

from src.services.decay import compute_strength

load_dotenv()

PRUNE_THRESHOLD = 0.05  # edges weaker than this are deleted


def run():
    conn = psycopg2.connect(os.getenv("DATABASE_URL"))
    cur = conn.cursor(cursor_factory=RealDictCursor)

    cur.execute("""
        SELECT id, memory_type, importance, recall_count, last_accessed_at
        FROM memories
    """)
    edges = cur.fetchall()

    updated = 0
    pruned = 0

    for edge in edges:
        strength = compute_strength(
            last_accessed_at=edge["last_accessed_at"],
            recall_count=edge["recall_count"],
            importance=edge["importance"],
        )

        if strength < PRUNE_THRESHOLD:
            cur.execute("DELETE FROM memories WHERE id = %s", (edge["id"],))
            pruned += 1
        else:
            # Do NOT overwrite importance — it is the fixed user-set base weight.
            # Strength is always computed fresh from importance + days + recall_count.
            updated += 1

    conn.commit()
    cur.close()
    conn.close()

    print(f"Decay job complete — updated: {updated}, pruned: {pruned}")


if __name__ == "__main__":
    run()
