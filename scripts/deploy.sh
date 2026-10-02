#!/usr/bin/env bash
set -euo pipefail

BACKEND_NEW="$1"
FRONTEND_NEW="$2"
cd "$(dirname "$0")/.."

set_env() {
  if grep -q "^$1=" .env; then
    sed -i "s|^$1=.*|$1=$2|" .env
  else
    echo "$1=$2" >> .env
  fi
}
get_env() { grep "^$1=" .env | cut -d= -f2- || true; }

PREV_BACKEND="$(get_env BACKEND_IMAGE)"
PREV_FRONTEND="$(get_env FRONTEND_IMAGE)"

docker login ghcr.io -u "$GHCR_USER" --password-stdin >/dev/null
exec </dev/null

roll_out() {
  set_env BACKEND_IMAGE "$1"
  set_env FRONTEND_IMAGE "$2"
  docker compose pull backend frontend || return 1
  docker compose up -d --no-build backend frontend || return 1
  docker compose restart reverse-proxy || return 1
  docker compose up -d --no-build --wait --wait-timeout 180 || return 1
}

if roll_out "$BACKEND_NEW" "$FRONTEND_NEW"; then
  echo "Deployed $BACKEND_NEW"
  docker logout ghcr.io >/dev/null 2>&1 || true
  docker image prune -f >/dev/null
  exit 0
fi

echo "Deploy failed, rolling back"
if [ -n "$PREV_BACKEND" ] && [ -n "$PREV_FRONTEND" ]; then
  roll_out "$PREV_BACKEND" "$PREV_FRONTEND" || true
else
  sed -i '/^BACKEND_IMAGE=/d;/^FRONTEND_IMAGE=/d' .env
  docker compose up -d --build --wait --wait-timeout 180 || true
fi
docker logout ghcr.io >/dev/null 2>&1 || true
exit 1
