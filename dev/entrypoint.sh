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

info "================================"
info "git 설정: ${GIT_STATUS}"
info "개발 환경 준비 완료"
info "다음 단계: git clone 후 setup.sh 실행"
info "================================"
