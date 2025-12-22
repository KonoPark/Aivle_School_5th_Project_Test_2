#!/bin/bash
set -euo pipefail

echo "=== Installing/Updating Dependencies ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Kernel: $(uname -a)"

# --- Install Docker Engine (Amazon Linux 2023) ---
# AL2023은 amazon-linux-extras가 없고, 보통 dnf/yum로 docker 패키지를 설치합니다.
echo "Installing Docker packages..."
dnf -y install docker

echo "Enabling and starting Docker daemon..."
systemctl enable --now docker

# --- Ensure docker group + socket permissions ---
echo "Ensuring docker group exists and ec2-user is in docker group..."
getent group docker >/dev/null 2>&1 || groupadd docker
usermod -aG docker ec2-user || true

echo "Docker socket:"
ls -al /var/run/docker.sock || true

# --- Install/Ensure Docker Compose v2 plugin ---
# dnf에 docker-compose-plugin이 없을 수 있어 바이너리로 설치(네가 한 방식)를 자동화
echo "Installing Docker Compose v2 plugin..."
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
COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}"

curl -fsSL -o /usr/local/lib/docker/cli-plugins/docker-compose "$COMPOSE_URL"
chmod 755 /usr/local/lib/docker/cli-plugins/docker-compose

# docker가 플러그인을 보는 기본 경로를 타지 않는 케이스 대비(안전용)
mkdir -p /usr/libexec/docker/cli-plugins
cp -f /usr/local/lib/docker/cli-plugins/docker-compose /usr/libexec/docker/cli-plugins/docker-compose
chmod 755 /usr/libexec/docker/cli-plugins/docker-compose

# --- Install Buildx plugin (optional but keep) ---
echo "Installing Docker Buildx plugin..."
mkdir -p /usr/local/lib/docker/cli-plugins

BARCH="$(uname -m)"
if [ "$BARCH" = "x86_64" ]; then
  BARCH="amd64"
elif [ "$BARCH" = "aarch64" ]; then
  BARCH="arm64"
else
  echo "Unsupported arch for buildx: $BARCH"
  exit 1
fi

BUILDX_VERSION="v0.17.1"
BUILDX_URL="https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${BARCH}"
curl -fsSL -o /usr/local/lib/docker/cli-plugins/docker-buildx "$BUILDX_URL"
chmod 755 /usr/local/lib/docker/cli-plugins/docker-buildx

# --- Verification (root context) ---
echo "=== Verification ==="
docker version
docker info >/dev/null
docker buildx version
docker compose version

echo "=== Dependencies installation completed ==="
