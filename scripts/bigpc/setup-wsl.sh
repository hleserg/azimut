#!/usr/bin/env bash
# bigPC WSL bootstrap: Docker + Structurizr Lite в режиме демона.
# Запускать в WSL на bigPC. Идемпотентный — можно запускать многократно.
#
# Документация: scripts/bigpc/README.md
# План: docs/_planning/05-rebuild-plan.md раздел 4.1 (вариант Б)

set -euo pipefail

REPO_URL="${REPO_URL:-git@github.com:hleserg/azimut.git}"
REPO_DIR="${REPO_DIR:-$HOME/azimut}"
BRANCH="${BRANCH:-docs/source-extraction}"
CONTAINER_NAME="azimuth-arch"
IMAGE="structurizr/lite"

log() { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33m[!]\033[0m %s\n' "$*"; }
err() { printf '\n\033[1;31m[ERR]\033[0m %s\n' "$*" >&2; }

# 1. Docker
if ! command -v docker >/dev/null 2>&1; then
  log "Docker not found — installing via get.docker.com"
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  cat <<EOF

============================================================
Docker installed. RE-LOGIN to WSL to apply 'docker' group:
  exit       # из WSL
  wsl        # снова войти
  bash scripts/bigpc/setup-wsl.sh   # запустить этот скрипт ещё раз
Либо: запустить 'newgrp docker' и продолжить в текущей сессии.
============================================================
EOF
  exit 0
fi
log "Docker found: $(docker --version)"

# 2. Docker daemon running?
if ! docker info >/dev/null 2>&1; then
  log "Docker daemon not running — starting"
  if command -v systemctl >/dev/null 2>&1 && systemctl --no-pager status >/dev/null 2>&1; then
    sudo systemctl start docker
  elif command -v service >/dev/null 2>&1; then
    sudo service docker start
  else
    sudo dockerd >/tmp/dockerd.log 2>&1 &
    sleep 3
  fi
fi
docker info >/dev/null 2>&1 || { err "Docker daemon still not responsive — see /tmp/dockerd.log"; exit 1; }

# 3. Repository
if [ ! -d "$REPO_DIR/.git" ]; then
  log "Cloning $REPO_URL into $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
  git checkout "$BRANCH"
else
  log "Repo exists — fetching and switching to $BRANCH"
  cd "$REPO_DIR"
  git fetch --all --prune
  git checkout "$BRANCH"
  git pull --ff-only
fi
log "Repo on $(git rev-parse --abbrev-ref HEAD) at $(git rev-parse --short HEAD)"

# 4. Pull image
log "Pulling $IMAGE"
docker pull "$IMAGE"

# 5. Replace container (idempotent)
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  log "Removing existing container '$CONTAINER_NAME'"
  docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker rm   "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

log "Starting container '$CONTAINER_NAME' (port 8080, volume $REPO_DIR)"
docker run -d \
  --restart=unless-stopped \
  --name "$CONTAINER_NAME" \
  -p 8080:8080 \
  -v "$REPO_DIR:/usr/local/structurizr" \
  "$IMAGE"

# 6. Verify
sleep 3
if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  log "Container is up:"
  docker ps --filter "name=$CONTAINER_NAME" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  cat <<EOF

============================================================
azimuth-arch is RUNNING.
- From WSL / bigPC localhost:  http://localhost:8080
- From LAN (after setup-windows.ps1 on bigPC Windows):
                                http://bigPC:8080
- Logs:                         docker logs -f azimuth-arch
- Stop:                         docker stop azimuth-arch
- Update DSL on bigPC:          cd ~/azimut && git pull
  (Structurizr Lite watches volume — picks up changes automatically.)
============================================================
EOF
else
  err "Container failed to start. See: docker logs $CONTAINER_NAME"
  exit 1
fi
