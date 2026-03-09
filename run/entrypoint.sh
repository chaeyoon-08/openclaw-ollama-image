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
echo "  OpenClaw AI 업무 비서팀 (run)"
echo "=================================================="
echo ""

# ── 1. GitHub 환경변수 처리 (선택) ──────────────────────────
section "Git 설정"

if [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_EMAIL" ] && [ -n "$GITHUB_TOKEN" ]; then
  git config --global user.name  "$GITHUB_USERNAME"
  git config --global user.email "$GITHUB_EMAIL"
  git config --global credential.helper store
  echo "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
  chmod 600 ~/.git-credentials
  info "Git 설정 완료"
else
  warn "GITHUB_USERNAME / GITHUB_EMAIL / GITHUB_TOKEN 미설정 — Git 인증 없이 진행"
fi

# ── 2. OpenClaw 설정 (openclaw.json) ────────────────────────
section "OpenClaw 설정"

OPENCLAW_DIR="$HOME/.openclaw"
mkdir -p "$OPENCLAW_DIR"

OLLAMA_MODEL_CFG="${OLLAMA_MODEL:-qwen3-coder:32b}"

cat > "$OPENCLAW_DIR/openclaw.json" << EOF
{
  "models": {
    "mode": "merge",
    "providers": {
      "ollama": {
        "baseUrl": "http://127.0.0.1:11434",
        "apiKey": "ollama-local",
        "api": "openai-completions"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/${OLLAMA_MODEL_CFG}",
        "fallbacks": ["ollama/glm4:latest"]
      }
    }
  },
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "open",
      "allowFrom": ["*"]
    }
  },
  "env": {
    "GOOGLE_CLIENT_ID": "${GOOGLE_CLIENT_ID}",
    "GOOGLE_CLIENT_SECRET": "${GOOGLE_CLIENT_SECRET}",
    "GOOGLE_REFRESH_TOKEN": "${GOOGLE_REFRESH_TOKEN}"
  },
  "gateway": {
    "mode": "local"
  }
}
EOF
info "openclaw.json 설정 완료"

# ── 3. Ollama 서비스 시작 ────────────────────────────────────
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

# ── 3. 모델 로드 ─────────────────────────────────────────────
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

# ── 5. 에이전트 등록 ─────────────────────────────────────────
section "에이전트 등록"

for AGENT in orchestrator mail-agent calendar-agent drive-agent; do
  openclaw agents add "$AGENT" \
    --workspace /workspace \
    --model "ollama/${OLLAMA_MODEL}" \
    --non-interactive \
    2>/dev/null \
    || info "  ${AGENT}: 이미 등록됨 (스킵)"
done
info "에이전트 등록 완료"

# ── 6. OpenClaw 시작 ─────────────────────────────────────────
section "OpenClaw 시작"

echo ""
echo "=================================================="
echo "  모든 준비 완료. Telegram 봇에 메시지를 보내보세요."
echo "=================================================="
echo ""

exec openclaw start
