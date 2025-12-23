#!/bin/bash
set -euo pipefail

echo "=== Preparing Docker environment (idempotent) ==="
echo "[INFO] Running as: $(id)"

# 1) 기본 패키지
dnf -y update
dnf -y install docker curl unzip || true

# 2) AWS CLI v2 (없으면 설치)
if ! command -v aws >/dev/null 2>&1; then
  echo "[INFO] Installing AWS CLI v2..."
  curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip || true
  if [ -f /tmp/awscliv2.zip ]; then
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install --update
  fi
fi

# 3) Docker 데몬 기동/활성화
systemctl enable --now docker
systemctl is-active --quiet docker
echo "[OK] docker is running"

# 4) docker 그룹 + ec2-user 권한
getent group docker >/dev/null 2>&1 || groupadd docker
usermod -aG docker ec2-user || true

# 5) Docker Compose v2 플러그인 (없으면 설치)
if docker compose version >/dev/null 2>&1; then
  echo "[OK] docker compose already available: $(docker compose version)"
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

  curl -sSL -o /usr/local/lib/docker/cli-plugins/docker-compose "$URL"
  chmod 755 /usr/local/lib/docker/cli-plugins/docker-compose
  docker compose version
fi

echo "=== Docker environment ready ==="
echo "[INFO] docker sock: $(ls -al /var/run/docker.sock || true)"
