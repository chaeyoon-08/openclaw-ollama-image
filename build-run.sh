#!/bin/bash
# =============================================================
# openclaw-ollama-image / build-run.sh
# run 이미지 로컬 빌드 + ghcr.io 푸시 스크립트
#
# 사용법:
#   ./build-run.sh          → latest 태그로 빌드 + 푸시
#   ./build-run.sh v1.0.0   → latest + v1.0.0 태그로 빌드 + 푸시
#
# 필수 환경변수:
#   GITHUB_USERNAME — GitHub 사용자명
#   GITHUB_TOKEN    — GitHub Personal Access Token (write:packages 권한 필요)
# =============================================================

set -eo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() { echo -e "\n${CYAN}▶ $1${NC}"; }

# ── 1. 환경변수 확인 ──────────────────────────────────────────
section "환경변수 확인"

: "${GITHUB_USERNAME:?'GITHUB_USERNAME 이 설정되지 않았습니다'}"
: "${GITHUB_TOKEN:?'GITHUB_TOKEN 이 설정되지 않았습니다 (write:packages 권한 필요)'}"

VERSION_TAG="${1:-}"
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
IMAGE_BASE="ghcr.io/${GITHUB_USERNAME}/openclaw-ollama-image-run"

info "이미지: $IMAGE_BASE"
info "커밋:   $COMMIT_HASH"
[ -n "$VERSION_TAG" ] && info "버전:   $VERSION_TAG"

# ── 2. ghcr.io 로그인 ─────────────────────────────────────────
section "ghcr.io 로그인"

echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin
info "로그인 완료"

# ── 3. 빌드 ───────────────────────────────────────────────────
section "Docker 이미지 빌드"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "빌드 중... (시간이 걸릴 수 있습니다)"
docker build \
  --platform linux/amd64 \
  -t "${IMAGE_BASE}:latest" \
  -t "${IMAGE_BASE}:sha-${COMMIT_HASH}" \
  ${VERSION_TAG:+-t "${IMAGE_BASE}:${VERSION_TAG}"} \
  "$SCRIPT_DIR/run"

info "빌드 완료"

# ── 4. 푸시 ───────────────────────────────────────────────────
section "ghcr.io 푸시"

docker push "${IMAGE_BASE}:latest"
info "푸시 완료: ${IMAGE_BASE}:latest"

docker push "${IMAGE_BASE}:sha-${COMMIT_HASH}"
info "푸시 완료: ${IMAGE_BASE}:sha-${COMMIT_HASH}"

if [ -n "$VERSION_TAG" ]; then
  docker push "${IMAGE_BASE}:${VERSION_TAG}"
  info "푸시 완료: ${IMAGE_BASE}:${VERSION_TAG}"
fi

# ── 완료 ──────────────────────────────────────────────────────
echo ""
echo "=================================================="
echo "  빌드 + 푸시 완료!"
echo ""
echo "  pull 명령:"
echo "    docker pull ${IMAGE_BASE}:latest"
[ -n "$VERSION_TAG" ] && \
echo "    docker pull ${IMAGE_BASE}:${VERSION_TAG}"
echo ""
echo "  실행:"
echo "    cd run && docker compose up -d"
echo "=================================================="
echo ""
