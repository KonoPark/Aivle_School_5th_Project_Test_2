#!/bin/bash
set -euo pipefail

echo "=== [AfterInstall] Preparing Docker environment (idempotent) ==="
echo "Time: $(date -u)"
echo "User: $(id)"

# 0) 필수 패키지
dnf -y install curl ca-certificates >/dev/null 2>&1 || true

# 1) Docker 설치 (없으면)
if ! command -v docker >/dev/null 2>&1; then
  echo "[INFO] Docker not found. Installing..."
  dnf -y update
  dnf -y install docker
else
  echo "[OK] Docker already installed: $(docker --version)"
fi

# 2) Docker 데몬 활성화/기동
systemctl enable --now docker
systemctl is-active --quiet docker && echo "[OK] docker.service is active"

# 3) docker 그룹 + ec2-user 그룹 추가 (원하면 SSH로 ec2-user가 바로 docker 쓰게)
getent group docker >/dev/null 2>&1 || groupadd docker
usermod -aG docker ec2-user || true

# 4) Docker Compose v2 플러그인 설치/확인
# - 우선 패키지로 가능하면 그게 제일 깔끔 (환경에 따라 패키지명이 없을 수 있어 fallback 유지)
if docker compose version >/dev/null 2>&1; then
  echo "[OK] docker compose already available: $(docker compose version)"
else
  echo "[INFO] docker compose not available. Installing plugin binary..."

  mkdir -p /usr/local/lib/docker/cli-plugins

  ARCH="$(uname -m)"
  if [ "$ARCH" = "x86_64" ]; then
    ARCH="x86_64"
  elif [ "$ARCH" = "aarch64" ]; then
    ARCH="aarch64"
  else
    echo "[ERROR] Unsupported arch: $ARCH"
    exit 1
  fi

  COMPOSE_VERSION="v2.27.0"
  URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}"

  echo "[INFO] Downloading: $URL"
  curl -fsSL -o /usr/local/lib/docker/cli-plugins/docker-compose "$URL"
  chmod 755 /usr/local/lib/docker/cli-plugins/docker-compose

  echo "[OK] Installed: $(/usr/local/lib/docker/cli-plugins/docker-compose version)"
  docker compose version
fi

echo "=== [AfterInstall] Docker environment ready ==="
