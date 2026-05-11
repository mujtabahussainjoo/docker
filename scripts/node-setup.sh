#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

docker compose exec node sh -lc "node -v && npm -v"

if [ -f src/package.json ]; then
  docker compose exec node sh -lc "cd /var/www/html && npm install"
  echo "Node dependencies installed from src/package.json"
else
  echo "No package.json found in src/. Skipping npm install."
fi