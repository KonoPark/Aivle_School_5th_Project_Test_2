#!/bin/bash
set -euo pipefail

echo "=== AfterInstall: Preparing Docker environment (idempotent) ==="
date
echo "User: $(id)"

# 1) docker 설치
if ! command -v docker >/dev/null 2>&1; then
  echo "[INFO] Docker not found. Installing..."
  dnf -y update
  dnf -y install docker
fi

# 2) docker 데몬 활성화
systemctl enable --now docker

# 3) docker 그룹/권한
getent group docker >/dev/null 2>&1 || groupadd docker
usermod -aG docker ec2-user || true

# 4) docker compose 플러그인
if docker compose version >/dev/null 2>&1; then
  echo "[OK] docker compose already available: $(docker compose version)"
else
  echo "[INFO] Installing docker compose plugin..."
  mkdir -p /usr/local/lib/docker/cli-plugins

  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64)  BIN="docker-compose-linux-x86_64" ;;
    aarch64) BIN="docker-compose-linux-aarch64" ;;
    *) echo "Unsupported arch: $ARCH"; exit 1 ;;
  esac

  COMPOSE_VERSION="v2.27.0"
  URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/${BIN}"

  curl -L -o /usr/local/lib/docker/cli-plugins/docker-compose "$URL"
  chmod 755 /usr/local/lib/docker/cli-plugins/docker-compose

  docker compose version
fi

echo "=== AfterInstall: Docker ready ==="
