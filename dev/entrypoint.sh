#!/bin/bash
set -eo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
section() { echo -e "\n${CYAN}▶ $1${NC}"; }

echo ""
echo "=================================================="
echo "  OpenClaw AI 업무 비서팀 (dev)"
echo "=================================================="
echo ""

# ── 1. Git 설정 ──────────────────────────────────────────────
section "Git 설정"

if [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_EMAIL" ] && [ -n "$GITHUB_TOKEN" ]; then
  git config --global user.name  "$GITHUB_USERNAME"
  git config --global user.email "$GITHUB_EMAIL"
  git config --global credential.helper store
  echo "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
  chmod 600 ~/.git-credentials
  info "Git 설정 완료"
else
  info "GitHub 계정 정보가 입력되지 않아 git 설정을 건너뜁니다."
fi

# ── 2. Ollama 서비스 시작 ─────────────────────────────────────
section "Ollama 서비스 시작"

ollama serve &>/dev/null &

info "Ollama 준비 대기 중..."
MAX_WAIT=60
COUNT=0
until curl -sf http://127.0.0.1:11434/api/tags &>/dev/null; do
  sleep 2
  COUNT=$((COUNT + 2))
  if [ "$COUNT" -ge "$MAX_WAIT" ]; then
    error "Ollama 시작 타임아웃 (${MAX_WAIT}초)"
    exit 1
  fi
done
info "Ollama 준비 완료"

# ── 3. 모델 로드 ──────────────────────────────────────────────
section "LLM 모델 로드"

OLLAMA_MODEL="${OLLAMA_MODEL:-qwen3-coder:32b}"
FALLBACK_MODEL="glm4:latest"

if ollama list | grep -q "^${OLLAMA_MODEL}"; then
  info "모델 이미 존재: $OLLAMA_MODEL (스킵)"
else
  info "모델 다운로드 중: $OLLAMA_MODEL"
  info "(모델 크기에 따라 10~30분 소요될 수 있습니다)"
  if ollama pull "$OLLAMA_MODEL"; then
    info "$OLLAMA_MODEL 다운로드 완료"
  else
    warn "$OLLAMA_MODEL 다운로드 실패 → fallback: $FALLBACK_MODEL"
    ollama pull "$FALLBACK_MODEL" \
      || { error "Fallback 모델($FALLBACK_MODEL) 다운로드도 실패했습니다"; exit 1; }
    OLLAMA_MODEL="$FALLBACK_MODEL"
    info "$OLLAMA_MODEL (fallback) 다운로드 완료"
  fi
fi

# ── 4. OpenClaw 시작 ──────────────────────────────────────────
section "OpenClaw 시작"

echo ""
echo "=================================================="
echo "  모든 준비 완료. Telegram 봇에 메시지를 보내보세요."
echo "=================================================="
echo ""

exec openclaw start
