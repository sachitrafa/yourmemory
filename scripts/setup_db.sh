#!/usr/bin/env bash
# YourMemory — one-shot database setup (no Docker required)
# Installs PostgreSQL + pgvector, creates the database, runs migrations.
#
# Usage:
#   bash scripts/setup_db.sh
#   bash scripts/setup_db.sh --db-name mydb --user myuser

set -e

DB_NAME=${DB_NAME:-yourmemory}
DB_USER=${DB_USER:-$(whoami)}
DB_PORT=${DB_PORT:-5432}

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[x]${NC} $*"; exit 1; }

# ── 1. Install Postgres + pgvector ───────────────────────────────────────────

if command -v psql &>/dev/null; then
    info "PostgreSQL already installed: $(psql --version)"
else
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &>/dev/null; then
            error "Homebrew not found. Install it from https://brew.sh then re-run."
        fi
        info "Installing PostgreSQL via Homebrew..."
        brew install postgresql@16
        brew link postgresql@16 --force
        brew services start postgresql@16
    elif command -v apt-get &>/dev/null; then
        info "Installing PostgreSQL via apt..."
        sudo apt-get update -q
        sudo apt-get install -y postgresql postgresql-contrib
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    else
        error "Unsupported OS. Install PostgreSQL manually from https://www.postgresql.org/download/"
    fi
fi

# ── 2. Install pgvector ───────────────────────────────────────────────────────

PG_VERSION=$(psql --version | grep -oE '[0-9]+' | head -1)

if psql -U "$DB_USER" -c "SELECT extversion FROM pg_extension WHERE extname='vector';" "$DB_NAME" 2>/dev/null | grep -q '[0-9]'; then
    info "pgvector already installed."
else
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! brew list pgvector &>/dev/null; then
            info "Installing pgvector via Homebrew..."
            brew install pgvector
        fi
    elif command -v apt-get &>/dev/null; then
        info "Installing pgvector via apt..."
        sudo apt-get install -y postgresql-$PG_VERSION-pgvector 2>/dev/null || {
            warn "apt pgvector not found — building from source..."
            sudo apt-get install -y postgresql-server-dev-$PG_VERSION git build-essential
            git clone --depth 1 https://github.com/pgvector/pgvector.git /tmp/pgvector
            cd /tmp/pgvector && make && sudo make install && cd -
        }
    fi
fi

# ── 3. Create database ────────────────────────────────────────────────────────

if psql -U "$DB_USER" -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    info "Database '$DB_NAME' already exists."
else
    info "Creating database '$DB_NAME'..."
    createdb -U "$DB_USER" "$DB_NAME"
fi

# ── 4. Write .env ─────────────────────────────────────────────────────────────

DATABASE_URL="postgresql://${DB_USER}@localhost:${DB_PORT}/${DB_NAME}"

if [ -f .env ] && grep -q "DATABASE_URL" .env; then
    warn ".env already has DATABASE_URL — skipping (edit manually if needed)."
else
    info "Writing DATABASE_URL to .env..."
    echo "DATABASE_URL=${DATABASE_URL}" >> .env
fi

# ── 5. Run migrations ─────────────────────────────────────────────────────────

info "Running database migrations..."
DATABASE_URL="$DATABASE_URL" python main.py &
PID=$!
sleep 3
kill $PID 2>/dev/null || true

echo ""
info "Setup complete!"
echo ""
echo "  DATABASE_URL=${DATABASE_URL}"
echo ""
echo "  Start the server:   python main.py"
echo "  Or install as MCP:  add to claude_desktop_config.json"
echo ""
