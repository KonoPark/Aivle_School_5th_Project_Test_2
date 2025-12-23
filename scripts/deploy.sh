#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/mini_project5"
cd "$APP_DIR"

echo "Starting deployment at $(date)"
echo "User: $(id)"
echo "PWD: $(pwd)"
echo "Docker sock: $(ls -al /var/run/docker.sock || true)"

# compose 파일 확인
COMPOSE_FILE=""
if [ -f docker-compose.yml ]; then
  COMPOSE_FILE="docker-compose.yml"
elif [ -f compose.yml ]; then
  COMPOSE_FILE="compose.yml"
else
  echo "[ERROR] docker-compose.yml (or compose.yml) not found in $APP_DIR"
  ls -al
  exit 1
fi
echo "[INFO] Using compose file: $COMPOSE_FILE"

# Docker 접근 확인
docker info >/dev/null

# ---- ECR 로그인 (compose에 ECR image가 있을 때만) ----
# 예: 4162...dkr.ecr.us-east-1.amazonaws.com/my-frontend:latest
ECR_REGISTRIES=$(grep -E '^\s*image:\s*[0-9]{12}\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com/' "$COMPOSE_FILE" \
  | sed -E 's/^\s*image:\s*//' \
  | sed -E 's#^([0-9]{12}\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com)/.*#\1#' \
  | sort -u || true)

if [ -n "${ECR_REGISTRIES}" ]; then
  echo "[INFO] Detected ECR registries:"
  echo "${ECR_REGISTRIES}"

  # 리전은 레지스트리에서 추출 (여러 개면 각각 처리)
  for REG in ${ECR_REGISTRIES}; do
    REGION=$(echo "$REG" | sed -E 's/^[0-9]{12}\.dkr\.ecr\.([a-z0-9-]+)\.amazonaws\.com$/\1/')
    echo "[INFO] ECR login: registry=$REG region=$REGION"

    aws ecr get-login-password --region "$REGION" \
      | docker login --username AWS --password-stdin "$REG"
  done
else
  echo "[INFO] No ECR image detected in compose. Skipping ECR login."
fi

echo "Stopping existing containers..."
docker compose -f "$COMPOSE_FILE" down || true

# ECR image 쓰는 경우 pull이 필요 (build인 경우 pull은 harmless)
echo "Pulling images (if any)..."
docker compose -f "$COMPOSE_FILE" pull || true

echo "Building and starting new containers..."
docker compose -f "$COMPOSE_FILE" up -d --build

echo "Deployment finished. Checking ps..."
docker compose -f "$COMPOSE_FILE" ps

echo "Recent logs (last 80 lines) for quick check..."
docker compose -f "$COMPOSE_FILE" logs --tail=80 || true
