import os
from dotenv import load_dotenv
from src.db.connection import get_backend, get_conn

load_dotenv()


def migrate():
    backend = get_backend()
    schema_file = "schema.sql" if backend == "postgres" else "sqlite_schema.sql"
    schema_path = os.path.join(os.path.dirname(__file__), schema_file)

    with open(schema_path, "r") as f:
        schema = f.read()

    conn = get_conn()
    cur = conn.cursor()

    if backend == "sqlite":
        # executescript handles multiple statements and comments correctly
        conn.executescript(schema)
    else:
        cur.execute(schema)
        conn.commit()

    cur.close()
    conn.close()
    print(f"Migration complete ({backend}).")


if __name__ == "__main__":
    migrate()
