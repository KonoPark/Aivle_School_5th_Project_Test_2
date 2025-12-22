#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/mini_project5"

echo "=== Starting deployment ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "PWD(before): $(pwd)"
echo "Groups: $(id)"

cd "$APP_DIR"
echo "PWD(after): $(pwd)"
ls -al

# compose 파일 존재 확인 (없으면 바로 실패 -> 원인 명확)
if [ ! -f docker-compose.yml ] && [ ! -f docker-compose.yaml ]; then
  echo "ERROR: docker-compose.yml or docker-compose.yaml not found in $APP_DIR"
  echo "Files in app dir:"
  ls -al
  exit 1
fi

# Docker daemon 접속 가능 확인 (여기서 permission/daemon 문제면 즉시 드러남)
echo "Checking docker daemon connectivity..."
docker info >/dev/null

echo "Docker Compose version:"
docker compose version

# 기존 컨테이너 중지 (에러 무시)
echo "Stopping existing containers..."
docker compose down || true

# 최신 이미지 빌드 및 실행
echo "Building and starting new containers..."
docker compose up -d --build

# 확인
echo "Deployment finished. Checking ps..."
docker compose ps

echo "=== Deployment completed successfully ==="
