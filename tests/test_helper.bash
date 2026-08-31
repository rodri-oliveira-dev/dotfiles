#!/usr/bin/env bash

ORIGINAL_PATH="${ORIGINAL_PATH:-$PATH}"

setup_dotfiles_test() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TEST_HOME="$BATS_TEST_TMPDIR/home"

  mkdir -p "$TEST_HOME"

  export REPO_ROOT
  export HOME="$TEST_HOME"
  export XDG_CONFIG_HOME="$HOME/.config"
  export GIT_CONFIG_NOSYSTEM=1
  export PATH="$HOME/.local/bin:$ORIGINAL_PATH"
}

create_fake_dotnet() {
  FAKE_BIN="$BATS_TEST_TMPDIR/fake-bin"
  DOTNET_LOG="$BATS_TEST_TMPDIR/dotnet.log"

  mkdir -p "$FAKE_BIN"
  : >"$DOTNET_LOG"

  cat >"$FAKE_BIN/dotnet" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s|%s\n' "$PWD" "$*" >>"${DOTNET_LOG:?}"

if [[ "${1:-}" == "--version" ]]; then
  printf '%s\n' "${FAKE_DOTNET_VERSION:-10.0.400}"
fi
EOF

  chmod +x "$FAKE_BIN/dotnet"

  export FAKE_BIN
  export DOTNET_LOG
  export FAKE_DOTNET_VERSION="10.0.400"
  export PATH="$FAKE_BIN:$ORIGINAL_PATH"
}

create_git_project() {
  local name="${1:-project}"

  PROJECT_ROOT="$BATS_TEST_TMPDIR/$name"
  mkdir -p "$PROJECT_ROOT/src/nested"
  git init -q "$PROJECT_ROOT"

  export PROJECT_ROOT
}

assert_contains() {
  local haystack="$1"
  local expected="$2"

  [[ "$haystack" == *"$expected"* ]]
}
