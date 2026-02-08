#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  IMA — Starting All Local Docker Services"
echo "============================================"

# Load .env if present
if [ -f "$SCRIPT_DIR/.env" ]; then
  echo "📄 Loading .env file..."
  set -a; source "$SCRIPT_DIR/.env"; set +a
fi

# Create shared network if it doesn't exist
if ! docker network inspect ima-network >/dev/null 2>&1; then
  echo "🌐 Creating Docker network: ima-network"
  docker network create ima-network
fi


# ── 1. PostgreSQL ────────────────────────────────────────────
echo ""
echo "🐘 [1/2] Starting PostgreSQL..."
docker compose -f "$SCRIPT_DIR/Postgres/docker-compose.yml" --env-file "$SCRIPT_DIR/.env" up -d 2>/dev/null || \
docker compose -f "$SCRIPT_DIR/Postgres/docker-compose.yml" up -d

echo "   Waiting for Postgres health..."
for i in $(seq 1 30); do
  if docker exec intelligent-mfg-assistant-postgres pg_isready -U "${POSTGRES_USER:-postgres}" >/dev/null 2>&1; then
    echo "   ✅ PostgreSQL is ready"
    break
  fi
  [ "$i" -eq 30 ] && echo "   ⚠️  Postgres health timeout — continuing anyway"
  sleep 1
done

# ── 2. Redis ─────────────────────────────────────────────────
echo ""
echo "🔴 [2/2] Starting Redis..."
docker compose -f "$SCRIPT_DIR/Redis/docker-compose.yml" --env-file "$SCRIPT_DIR/.env" up -d 2>/dev/null || \
docker compose -f "$SCRIPT_DIR/Redis/docker-compose.yml" up -d


# ── Summary ──────────────────────────────────────────────────
echo ""
echo "============================================"
echo "  ✅ All 2 services started!"
echo ""
echo "  PostgreSQL:  localhost:${POSTGRES_PORT:-5432}"
echo "  Redis:       localhost:${REDIS_PORT:-6379}"
echo "============================================"