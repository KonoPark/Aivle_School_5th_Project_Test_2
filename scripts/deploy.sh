#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/mini_project5"

echo "Starting deployment at $(date)"
echo "User: $(id)"
echo "Docker sock: $(ls -al /var/run/docker.sock || true)"

cd "$APP_DIR"

if [ ! -f docker-compose.yml ] && [ ! -f compose.yml ]; then
  echo "[ERROR] docker-compose.yml (or compose.yml) not found in $APP_DIR"
  ls -al
  exit 1
fi

# docker 접근 확인 (실패 시 메시지 출력)
if ! docker info >/dev/null 2>&1; then
  echo "[ERROR] docker daemon or permission issue."
  docker info || true
  echo "Hint: ensure ec2-user is in docker group and session refreshed (re-login) or run deploy as root."
  exit 1
fi

echo "Stopping existing containers..."
docker compose down || true

echo "Pulling latest images..."
docker compose pull

echo "Starting containers..."
docker compose up -d

echo "Deployment finished. Checking ps..."
docker compose ps
