#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  IMA — DELETE All Local Docker Resources"
echo "============================================"
echo ""
echo "⚠️  This will remove ALL containers, volumes, and data!"
echo "   You will lose all local database contents."
echo ""

read -rp "Type 'yes' to confirm: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

echo ""

echo "🔴 Removing Redis + volumes..."
docker compose -f "$SCRIPT_DIR/Redis/docker-compose.yml" down -v 2>/dev/null || true
echo "🐘 Removing PostgreSQL + volumes..."
docker compose -f "$SCRIPT_DIR/Postgres/docker-compose.yml" down -v 2>/dev/null || true

echo "🌐 Removing network..."
docker network rm ima-network 2>/dev/null || true

echo ""
echo "🗑️  All IMA Docker resources have been deleted."