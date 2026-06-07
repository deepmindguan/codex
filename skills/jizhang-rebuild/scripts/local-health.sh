#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-/Users/soros/Downloads/project/jizhang}"
WEB_DIR="$ROOT_DIR/web"
API_DIR="$ROOT_DIR/api"

echo "Project: $ROOT_DIR"
test -d "$WEB_DIR" || { echo "Missing web dir: $WEB_DIR" >&2; exit 1; }
test -d "$API_DIR" || { echo "Missing api dir: $API_DIR" >&2; exit 1; }

echo "Node: $(node --version)"
echo "npm: $(npm --version)"

echo "Checking frontend package..."
cd "$WEB_DIR"
npm run lint
npm run build

echo "Checking API package..."
cd "$API_DIR"
npm ci --omit=dev --prefer-offline
TMP_DB="$(mktemp -u /tmp/jizhang-health-XXXXXX.sqlite)"
DB_PATH="$TMP_DB" SYNC_KEY="local-health-check" node -e "import('./src/schema.js').then(() => import('./src/db.js')).then(() => console.log('api modules ok'))"
rm -f "$TMP_DB" "$TMP_DB-shm" "$TMP_DB-wal"

echo "Local health checks passed."
