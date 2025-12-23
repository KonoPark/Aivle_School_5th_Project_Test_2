#!/bin/bash
set -euo pipefail

echo "=== Preparing Docker environment (idempotent) ==="

# 1) Docker 설치 여부 확인 (없으면 설치)
if ! command -v docker >/dev/null 2>&1; then
  echo "[INFO] Docker not found. Installing..."
  dnf update -y
  dnf install -y docker
fi

# 2) Docker 데몬 기동/활성화
systemctl enable --now docker

# 3) docker 그룹 존재 + ec2-user를 docker 그룹에 포함
getent group docker >/dev/null 2>&1 || groupadd docker
usermod -aG docker ec2-user || true

# 4) Docker Compose v2 플러그인 설치(없을 때만)
# docker compose가 동작하는지만 기준으로 함
if docker compose version >/dev/null 2>&1; then
  echo "[OK] docker compose already available"
else
  echo "[INFO] Installing docker compose plugin..."
  mkdir -p /usr/local/lib/docker/cli-plugins

  ARCH="$(uname -m)"
  if [ "$ARCH" = "x86_64" ]; then
    ARCH="x86_64"
  elif [ "$ARCH" = "aarch64" ]; then
    ARCH="aarch64"
  else
    echo "Unsupported arch: $ARCH"
    exit 1
  fi

  COMPOSE_VERSION="v2.27.0"
  URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}"

  curl -L -o /usr/local/lib/docker/cli-plugins/docker-compose "$URL"
  chmod 755 /usr/local/lib/docker/cli-plugins/docker-compose

  # 설치 확인
  docker compose version
fi

echo "=== Docker environment ready ==="
