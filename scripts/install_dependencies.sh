#!/bin/bash
set -euo pipefail

echo "=== Preparing Docker environment (safe/idempotent) ==="

# Docker 설치는 '최초 1회'만 권장. 배포마다 설치/업데이트는 지양.
if ! command -v docker >/dev/null 2>&1; then
  echo "[INFO] Docker not found. Installing..."
  dnf install -y docker
fi

systemctl enable --now docker

# docker 그룹은 존재만 확인
getent group docker >/dev/null 2>&1 || groupadd docker

# ⚠️ 여기서 usermod는 배포마다 하지 않는 것을 권장
# 최초 1회 수동으로만 수행:
# sudo usermod -aG docker ec2-user
# 그리고 SSH 재로그인

echo "[INFO] docker version: $(docker --version || true)"
echo "[INFO] docker compose: $(docker compose version 2>/dev/null || echo 'NOT FOUND')"

echo "=== Docker environment ready ==="
