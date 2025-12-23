#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/mini_project5"
REGION="us-east-1"
ECR_REGISTRY="416225317325.dkr.ecr.us-east-1.amazonaws.com"

echo "=== ApplicationStart: Deploy ==="
date
echo "User: $(id)"
echo "Docker sock: $(ls -al /var/run/docker.sock || true)"

cd "$APP_DIR"

# compose 파일 확인
if [ ! -f docker-compose.yml ] && [ ! -f compose.yml ]; then
  echo "[ERROR] docker-compose.yml (or compose.yml) not found in $APP_DIR"
  ls -al
  exit 1
fi

# docker 접근 확인
docker info >/dev/null

# ECR 로그인 (root 컨텍스트에서)
echo "[INFO] ECR login: $ECR_REGISTRY"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo "[INFO] Pull latest images..."
docker compose pull

echo "[INFO] Starting containers..."
docker compose up -d

echo "[INFO] Status:"
docker compose ps
