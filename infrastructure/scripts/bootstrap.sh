#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="${1:-}"

if [[ -z "$SERVER_IP" ]]; then
  echo "Usage: $0 <server-ip>"
  exit 1
fi

DOKPLOY_URL="https://${SERVER_IP}:3000"

echo "Checking Dokploy status on ${DOKPLOY_URL}..."

check_dokploy() {
  curl -sk "${DOKPLOY_URL}/api/health" 2>/dev/null | jq -r '.status' 2>/dev/null || echo "unavailable"
}

MAX_ATTEMPTS=30
ATTEMPT=0

while [[ $ATTEMPT -lt $MAX_ATTEMPTS ]]; do
  STATUS=$(check_dokploy)

  if [[ "$STATUS" == "ok" ]]; then
    echo "Dokploy is running and healthy."
    echo ""
    echo "Next steps:"
    echo "1. Open ${DOKPLOY_URL} in your browser"
    echo "2. Complete the initial setup wizard"
    echo "3. Generate an API token from Settings > API"
    echo "4. Add the token to GitHub Secrets as DOKPLOY_TOKEN"
    exit 0
  fi

  ATTEMPT=$((ATTEMPT + 1))
  echo "Attempt ${ATTEMPT}/${MAX_ATTEMPTS}: Dokploy not ready yet..."
  sleep 10
done

echo "Error: Dokploy did not become ready within expected time."
echo "Check server logs via Hetzner console."
exit 1
