#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_TAG="${1:-dotfiles-lifecycle-test}"
ENV_SENTINEL="$REPO_ROOT/.env.docker-context-sentinel"
LOG_SENTINEL="$REPO_ROOT/docker-context-sentinel.log"
SAVE_DIR=""
ENV_VALUE="docker-env-sentinel-$$-$RANDOM"
LOG_VALUE="docker-log-sentinel-$$-$RANDOM"

cleanup() {
  rm -f -- "$ENV_SENTINEL" "$LOG_SENTINEL"

  if [[ -n "$SAVE_DIR" ]]; then
    rm -rf -- "$SAVE_DIR"
  fi
}

trap cleanup EXIT

printf '%s\n' "$ENV_VALUE" >"$ENV_SENTINEL"
printf '%s\n' "$LOG_VALUE" >"$LOG_SENTINEL"

git -C "$REPO_ROOT" check-ignore -q "$ENV_SENTINEL"
git -C "$REPO_ROOT" check-ignore -q "$LOG_SENTINEL"

docker build --file "$REPO_ROOT/Dockerfile.test" --tag "$IMAGE_TAG" "$REPO_ROOT"

docker run --rm "$IMAGE_TAG" sh -c '
  test ! -e /workspace/dotfiles/.env.docker-context-sentinel
  test ! -e /workspace/dotfiles/docker-context-sentinel.log
'

SAVE_DIR="$(mktemp -d)"
docker save --output "$SAVE_DIR/image.tar" "$IMAGE_TAG"
mkdir "$SAVE_DIR/extracted"
tar -xf "$SAVE_DIR/image.tar" -C "$SAVE_DIR/extracted"

if grep -aR -Fq -- "$ENV_VALUE" "$SAVE_DIR/extracted"; then
  echo "Error: fictitious .env sentinel leaked into a saved image layer." >&2
  exit 1
fi

if grep -aR -Fq -- "$LOG_VALUE" "$SAVE_DIR/extracted"; then
  echo "Error: Git-ignored log sentinel leaked into a saved image layer." >&2
  exit 1
fi

printf 'Docker context hardening test completed successfully.\n'
