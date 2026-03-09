# openclaw-ollama-image

**AI 업무 비서팀** — Telegram 봇 하나로 Gmail·Google Calendar·Google Drive를 AI가 처리합니다.

OpenClaw + Ollama 기반 오케스트레이션 멀티 에이전트 구조.
별도 API 비용 없이 Gcube GPU 클라우드에서 로컬 AI 모델을 실행합니다.

> Docker 이미지 버전 — 환경변수만 넣으면 바로 실행됩니다.
> 스크립트 설치 버전은 [openclaw-ollama-dev](https://github.com/your-org/openclaw-ollama-dev)를 참고하세요.

---

## run vs dev

| | run | dev |
|---|---|---|
| 대상 | 비개발자 | 개발자 |
| agents/skills | 이미지 내장 | 레포 git clone |
| GitHub 자격증명 | 선택 | 필수 |
| 이미지 빌드 | GitHub Actions 자동 빌드 | GitHub Actions 자동 빌드 |
| 커스터마이징 | 이미지 재빌드 필요 | 레포 수정 후 재시작 |

---

## 빠른 시작

### run — 비개발자용

```bash
# 1. .env 작성
cat > .env << 'EOF'
TELEGRAM_BOT_TOKEN=your-bot-token
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REFRESH_TOKEN=your-refresh-token
# 선택
GITHUB_USERNAME=your-github-id
GITHUB_EMAIL=your@email.com
GITHUB_TOKEN=your-github-token
OLLAMA_MODEL=qwen3-coder:32b
EOF

# 2. 실행
cd run
docker compose --env-file ../.env up -d
```

### dev — 개발자용

```bash
# 1. .env 작성
cat > .env << 'EOF'
GITHUB_USERNAME=your-github-id
GITHUB_EMAIL=your@email.com
GITHUB_TOKEN=your-github-token
TELEGRAM_BOT_TOKEN=your-bot-token
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REFRESH_TOKEN=your-refresh-token
# 선택 — 기본값: https://github.com/$GITHUB_USERNAME/openclaw-ollama-dev.git
# OPENCLAW_DEV_REPO=https://github.com/your-org/openclaw-ollama-dev.git
EOF

# 2. 실행
cd dev
docker compose --env-file ../.env up -d
```

---

## GitHub Actions 자동 빌드

run/dev 모두 GitHub Actions로 자동 빌드됩니다.

| 워크플로우 | 트리거 | 이미지 |
|---|---|---|
| `build-run.yml` | `run/**` 변경 또는 수동 | `ghcr.io/{owner}/openclaw-ollama-image-run` |
| `build-dev.yml` | `dev/**` 변경 또는 수동 | `ghcr.io/{owner}/openclaw-ollama-image-dev` |

이 레포를 fork하면 자신의 ghcr.io 네임스페이스에 자동으로 이미지가 빌드됩니다.

---

## Gcube에서 실행하는 방법

```bash
# 1. 서버 접속 후 docker compose 설치 확인
docker compose version

# 2. 이 레포 클론
git clone https://github.com/your-org/openclaw-ollama-image.git
cd openclaw-ollama-image

# 3. .env 작성 (위 빠른 시작 참고)

# 4. run 버전 실행
cd run
docker compose --env-file ../.env up -d

# 5. 로그 확인
docker compose logs -f
```

최초 실행 시 모델 다운로드(10~30분)가 진행됩니다.
`ollama-models` 볼륨에 캐시되므로 재시작 시에는 즉시 실행됩니다.

GPU 패스스루가 자동으로 설정되어 있습니다 (NVIDIA 드라이버 필요).

---

## 환경변수

| 변수명 | run | dev | 설명 |
|---|---|---|---|
| `TELEGRAM_BOT_TOKEN` | 필수 | 필수 | Telegram BotFather에서 발급 |
| `GOOGLE_CLIENT_ID` | 필수 | 필수 | Google Cloud Console에서 발급 |
| `GOOGLE_CLIENT_SECRET` | 필수 | 필수 | Google Cloud Console에서 발급 |
| `GOOGLE_REFRESH_TOKEN` | 필수 | 필수 | OAuth 인증 후 발급 |
| `GITHUB_USERNAME` | 선택 | 필수 | GitHub 사용자명 |
| `GITHUB_EMAIL` | 선택 | 필수 | GitHub 이메일 |
| `GITHUB_TOKEN` | 선택 | 필수 | GitHub Personal Access Token |
| `OLLAMA_MODEL` | 선택 | 선택 | 기본값: `qwen3-coder:32b` |
| `OPENCLAW_DEV_REPO` | — | 선택 | 클론할 레포 URL (dev만) |

---

## 파일 구조

```
openclaw-ollama-image/
├── README.md
├── .github/
│   └── workflows/
│       ├── build-run.yml             # run 이미지 GitHub Actions 자동 빌드
│       └── build-dev.yml             # dev 이미지 GitHub Actions 자동 빌드
├── run/                              # 비개발자용
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── entrypoint.sh
│   ├── agents/
│   │   ├── orchestrator/AGENTS.md
│   │   ├── mail/AGENTS.md
│   │   ├── calendar/AGENTS.md
│   │   └── drive/AGENTS.md
│   └── skills/
│       ├── gmail/SKILL.md
│       ├── calendar/SKILL.md
│       └── drive/SKILL.md
└── dev/                              # 개발자용
    ├── Dockerfile
    ├── docker-compose.yml
    └── entrypoint.sh
```

---

## 권장 모델

| 모델 | VRAM | 특징 |
|---|---|---|
| `qwen3-coder:32b` | 24~32GB | Tool calling 안정성 최고, 기본값 |
| `glm4:latest` | 24~32GB | 범용성 우수, fallback용 |

---

## 관련 레포

| 레포 | 설명 |
|---|---|
| [openclaw-ollama-dev](https://github.com/your-org/openclaw-ollama-dev) | 스크립트 설치 버전 (이 레포의 원본) |
| openclaw-api-dev *(예정)* | OpenClaw + 외부 API 모델 버전 |
| openclaw-api-image *(예정)* | OpenClaw + 외부 API 모델 Docker 이미지 버전 |

---

## 라이선스

MIT
