#!/bin/bash
set -eo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC}  $1"; }

echo ""
echo "=================================================="
echo "  OpenClaw AI 업무 비서팀 (dev)"
echo "=================================================="
echo ""

# ── 1. Git 설정 ──────────────────────────────────────────────
GIT_STATUS="스킵"

if [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_EMAIL" ] && [ -n "$GITHUB_TOKEN" ]; then
  git config --global user.name  "$GITHUB_USERNAME"
  git config --global user.email "$GITHUB_EMAIL"
  git config --global credential.helper store
  echo "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
  chmod 600 ~/.git-credentials
  GIT_STATUS="완료"
fi

check_var() {
  local var="$1" suffix="$2"
  if [ -n "${!var}" ]; then
    info "${var}: 설정됨"
  else
    info "${var}${suffix} 설정되지 않았습니다. 워크로드의 환경변수를 추가해주세요."
  fi
}

info "================================"
info "git 설정: ${GIT_STATUS}"
check_var TELEGRAM_BOT_TOKEN    "이"
check_var GOOGLE_CLIENT_ID      "가"
check_var GOOGLE_CLIENT_SECRET  "이"
check_var GOOGLE_REFRESH_TOKEN  "이"
check_var OLLAMA_MODEL          "이"
check_var OLLAMA_FALLBACK_MODEL "이"
info "개발 환경 준비 완료"
info "================================"

tail -f /dev/null
