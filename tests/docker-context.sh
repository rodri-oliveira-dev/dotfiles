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

git -C "$REPO_ROOT" check-ignore -q -- ".env.docker-context-sentinel"
git -C "$REPO_ROOT" check-ignore -q -- "docker-context-sentinel.log"

docker build --file "$REPO_ROOT/Dockerfile.test" --tag "$IMAGE_TAG" "$REPO_ROOT"

docker run --rm "$IMAGE_TAG" sh -c '
  test ! -e /workspace/dotfiles/.env.docker-context-sentinel
  test ! -e /workspace/dotfiles/docker-context-sentinel.log
'

check_saved_layers_absent() {
  local sentinel="$1"
  local label="$2"
  local candidate
  local inspected_layers=0

  while IFS= read -r -d '' candidate; do
    if ! tar -tf "$candidate" >/dev/null 2>&1; then
      continue
    fi

    inspected_layers=$((inspected_layers + 1))

    if tar -xOf "$candidate" 2>/dev/null | grep -aF -- "$sentinel" >/dev/null; then
      echo "Error: $label leaked into a saved image layer." >&2
      return 1
    fi
  done < <(find "$SAVE_DIR/extracted" -type f -print0)

  if ((inspected_layers == 0)); then
    echo "Error: no saved image layers could be inspected." >&2
    return 1
  fi
}

SAVE_DIR="$(mktemp -d)"
docker save --output "$SAVE_DIR/image.tar" "$IMAGE_TAG"
mkdir "$SAVE_DIR/extracted"
tar -xf "$SAVE_DIR/image.tar" -C "$SAVE_DIR/extracted"

check_saved_layers_absent "$ENV_VALUE" "fictitious .env sentinel"
check_saved_layers_absent "$LOG_VALUE" "Git-ignored log sentinel"

printf 'Docker context hardening test completed successfully.\n'
