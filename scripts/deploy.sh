#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/mini_project5"

echo "Starting deployment at $(date)"
echo "User: $(id)"
echo "Docker sock: $(ls -al /var/run/docker.sock || true)"

cd "$APP_DIR"

# compose 파일 존재 확인
if [ ! -f docker-compose.yml ] && [ ! -f compose.yml ]; then
  echo "[ERROR] docker-compose.yml (or compose.yml) not found in $APP_DIR"
  ls -al
  exit 1
fi

# docker 접근 확인
docker info >/dev/null

echo "Stopping existing containers..."
docker compose down || true

echo "Building and starting new containers..."
docker compose up -d --build

echo "Deployment finished. Checking ps..."
docker compose ps
