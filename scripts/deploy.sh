#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/mini_project5"
AWS_REGION="us-east-1"
ECR_REGISTRY="416225317325.dkr.ecr.us-east-1.amazonaws.com"

echo "=== [ApplicationStart] Starting deployment ==="
echo "Time: $(date -u)"
echo "User: $(id)"
echo "PWD before cd: $(pwd)"
echo "Docker sock: $(ls -al /var/run/docker.sock || true)"
echo "Docker version: $(docker --version || true)"
echo "Compose version: $(docker compose version || true)"

cd "$APP_DIR"
echo "PWD after cd: $(pwd)"
ls -al | head -n 50

# 1) compose 파일 존재 확인
if [ ! -f docker-compose.yml ] && [ ! -f compose.yml ]; then
  echo "[ERROR] docker-compose.yml (or compose.yml) not found in $APP_DIR"
  exit 1
fi

# 2) Docker 데몬 접근 확인
docker info >/dev/null
echo "[OK] docker daemon reachable"

# 3) 포트 80 충돌 방지: 호스트 nginx가 있으면 내린다 (Docker nginx가 80을 쓰는 구조)
if systemctl list-unit-files | grep -q '^nginx\.service'; then
  if systemctl is-active --quiet nginx; then
    echo "[INFO] Host nginx is running. Stopping/disabling it to free port 80..."
    systemctl disable --now nginx || true
  else
    echo "[OK] Host nginx not active"
  fi
else
  echo "[OK] Host nginx service not installed"
fi

echo "[INFO] Checking port 80 listeners..."
ss -ltnp | grep ':80 ' || echo "[OK] port 80 appears free"

# 4) ECR 로그인 (root 실행 기준: root의 docker config 사용)
#    - IAM Role에 ecr:GetAuthorizationToken + ecr:BatchGetImage 등 권한 필요
echo "[INFO] Logging into ECR: $ECR_REGISTRY"
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

# 5) 기존 컨테이너 내리기
echo "[INFO] Stopping existing containers..."
docker compose down || true

# 6) 최신 이미지 pull (compose에서 image: ...:latest 쓰는 구조면 필수)
echo "[INFO] Pulling images..."
docker compose pull

# 7) 실행
echo "[INFO] Starting containers..."
docker compose up -d

# 8) 상태 출력
echo "=== [ApplicationStart] Deployment finished. docker compose ps ==="
docker compose ps

echo "=== [ApplicationStart] Done ==="
