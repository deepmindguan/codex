#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-118.145.224.120}"
USER="${2:-root}"
BASE_URL="http://$HOST"

echo "HTTP health: $BASE_URL/api/health"
curl -fsS "$BASE_URL/api/health"
echo

echo "Frontend assets:"
curl -fsS "$BASE_URL/" | grep -E '/assets/index-.+\.(js|css)' || {
  echo "Could not find built frontend assets in index.html" >&2
  exit 1
}

echo "Remote service checks:"
ssh "$USER@$HOST" "systemctl is-active jizhang-api && nginx -t && test -f /var/lib/jizhang-api/jizhang.sqlite && ls -lh /var/lib/jizhang-api/jizhang.sqlite"

echo "Remote health checks passed."
