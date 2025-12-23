#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/mini_project5"

echo "=== BeforeInstall: cleanup ==="
date
echo "User: $(id)"

# 1) 호스트 nginx가 80을 잡고 있으면 중지/비활성화
if systemctl is-active --quiet nginx 2>/dev/null; then
  echo "[INFO] Stopping host nginx (port 80 conflict)"
  systemctl disable --now nginx || true
fi

# 2) 기존 컨테이너 내려서 포트/네트워크 정리
if command -v docker >/dev/null 2>&1; then
  if [ -d "$APP_DIR" ]; then
    cd "$APP_DIR" || true
    if docker compose version >/dev/null 2>&1; then
      docker compose down || true
    fi
  fi
fi

# 3) CodeDeploy 파일 충돌 방지: 기존 앱 디렉토리 정리
#    (필요하면 .env 등 남길 파일은 아래 KEEP 목록으로 예외 처리)
if [ -d "$APP_DIR" ]; then
  echo "[INFO] Cleaning $APP_DIR to avoid file/dir conflicts (e.g., node_modules)"
  shopt -s dotglob
  rm -rf "$APP_DIR"/* || true
  shopt -u dotglob
else
  mkdir -p "$APP_DIR"
fi

echo "=== BeforeInstall: done ==="
