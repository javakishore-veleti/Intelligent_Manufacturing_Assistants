#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  IMA — Stopping All Local Docker Services"
echo "============================================"

echo "🔴 Stopping Redis..."
docker compose -f "$SCRIPT_DIR/Redis/docker-compose.yml" down 2>/dev/null || true

echo "🐘 Stopping PostgreSQL..."
docker compose -f "$SCRIPT_DIR/Postgres/docker-compose.yml" down 2>/dev/null || true

echo ""
echo "✅ All services stopped."