#!/usr/bin/env bats

load test_helper

setup() {
  setup_dotfiles_test
  create_fake_dotnet
  create_git_project
}

@test "dotnet-verify runs the full preflight for a single solution" {
  mkdir -p "$PROJECT_ROOT/.config"
  printf '{}\n' >"$PROJECT_ROOT/.config/dotnet-tools.json"
  : >"$PROJECT_ROOT/App.slnx"

  run bash -c 'cd "$1" && "$2"' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-verify"

  [ "$status" -eq 0 ]
  assert_contains "$output" "Repository verification completed successfully."

  mapfile -t commands <"$DOTNET_LOG"
  [ "${#commands[@]}" -eq 6 ]
  [ "${commands[0]}" = "$PROJECT_ROOT|--version" ]
  [ "${commands[1]}" = "$PROJECT_ROOT|tool restore" ]
  [ "${commands[2]}" = "$PROJECT_ROOT|restore $PROJECT_ROOT/App.slnx" ]
  [ "${commands[3]}" = "$PROJECT_ROOT|build $PROJECT_ROOT/App.slnx --no-restore" ]
  [ "${commands[4]}" = "$PROJECT_ROOT|format $PROJECT_ROOT/App.slnx --verify-no-changes --no-restore" ]
  [ "${commands[5]}" = "$PROJECT_ROOT|test $PROJECT_ROOT/App.slnx --no-build --no-restore" ]
}

@test "dotnet-verify quick mode restores and builds only" {
  : >"$PROJECT_ROOT/App.slnx"

  run bash -c 'cd "$1" && "$2" --quick' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-verify"

  [ "$status" -eq 0 ]
  grep -Fxq "$PROJECT_ROOT|--version" "$DOTNET_LOG"
  grep -Fq "$PROJECT_ROOT|restore $PROJECT_ROOT/App.slnx" "$DOTNET_LOG"
  grep -Fq "$PROJECT_ROOT|build $PROJECT_ROOT/App.slnx --no-restore" "$DOTNET_LOG"
  ! grep -Fq '|format ' "$DOTNET_LOG"
  ! grep -Fq '|test ' "$DOTNET_LOG"
}

@test "dotnet-verify supports skipping format and tests explicitly" {
  : >"$PROJECT_ROOT/App.slnx"

  run bash -c 'cd "$1" && "$2" --no-format --no-test' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-verify"

  [ "$status" -eq 0 ]
  grep -Fxq "$PROJECT_ROOT|--version" "$DOTNET_LOG"
  grep -Fq "$PROJECT_ROOT|restore $PROJECT_ROOT/App.slnx" "$DOTNET_LOG"
  grep -Fq "$PROJECT_ROOT|build $PROJECT_ROOT/App.slnx --no-restore" "$DOTNET_LOG"
  ! grep -Fq '|format ' "$DOTNET_LOG"
  ! grep -Fq '|test ' "$DOTNET_LOG"
}

@test "dotnet-verify refuses to choose between multiple root solutions" {
  : >"$PROJECT_ROOT/App.slnx"
  : >"$PROJECT_ROOT/Samples.slnx"

  run bash -c 'cd "$1" && "$2"' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-verify"

  [ "$status" -eq 2 ]
  assert_contains "$output" "Multiple solution files were found"
  assert_contains "$output" "App.slnx"
  assert_contains "$output" "Samples.slnx"

  mapfile -t commands <"$DOTNET_LOG"
  [ "${#commands[@]}" -eq 1 ]
  [ "${commands[0]}" = "$PROJECT_ROOT|--version" ]
}

@test "dotnet-verify accepts an explicit target when multiple solutions exist" {
  : >"$PROJECT_ROOT/App.slnx"
  : >"$PROJECT_ROOT/Samples.slnx"

  run bash -c 'cd "$1" && "$2" --quick Samples.slnx' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-verify"

  [ "$status" -eq 0 ]
  grep -Fxq "$PROJECT_ROOT|--version" "$DOTNET_LOG"
  grep -Fq "$PROJECT_ROOT|restore $PROJECT_ROOT/Samples.slnx" "$DOTNET_LOG"
  grep -Fq "$PROJECT_ROOT|build $PROJECT_ROOT/Samples.slnx --no-restore" "$DOTNET_LOG"
}

@test "dotnet-verify resolves the repository SDK when global.json exists" {
  cat >"$PROJECT_ROOT/global.json" <<'EOF'
{
  "sdk": {
    "version": "10.0.400"
  }
}
EOF
  : >"$PROJECT_ROOT/App.slnx"

  run bash -c 'cd "$1" && "$2" --quick' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-verify"

  [ "$status" -eq 0 ]
  assert_contains "$output" "Resolved SDK: 10.0.400"
  grep -Fxq "$PROJECT_ROOT|--version" "$DOTNET_LOG"
}

@test "dotnet-verify returns environment error when dotnet host exists without an SDK" {
  : >"$PROJECT_ROOT/App.slnx"

  cat >"$FAKE_BIN/dotnet" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s|%s\n' "$PWD" "$*" >>"${DOTNET_LOG:?}"

if [[ "${1:-}" == "--version" ]]; then
  exit 145
fi

exit 99
EOF
  chmod +x "$FAKE_BIN/dotnet"

  run bash -c 'cd "$1" && "$2" --quick' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-verify"

  [ "$status" -eq 2 ]
  assert_contains "$output" "Error: no .NET SDK could be resolved."

  mapfile -t commands <"$DOTNET_LOG"
  [ "${#commands[@]}" -eq 1 ]
  [ "${commands[0]}" = "$PROJECT_ROOT|--version" ]
}

@test "dotnet-verify stops on the first failed verification step" {
  : >"$PROJECT_ROOT/App.slnx"

  cat >"$FAKE_BIN/dotnet" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s|%s\n' "$PWD" "$*" >>"${DOTNET_LOG:?}"

if [[ "${1:-}" == "--version" ]]; then
  printf '%s\n' "10.0.400"
  exit 0
fi

if [[ "${1:-}" == "test" ]]; then
  exit 17
fi
EOF
  chmod +x "$FAKE_BIN/dotnet"

  run bash -c 'cd "$1" && "$2"' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-verify"

  [ "$status" -eq 1 ]
  assert_contains "$output" "Error: Running tests failed."
  grep -Fxq "$PROJECT_ROOT|--version" "$DOTNET_LOG"
  grep -Fq "$PROJECT_ROOT|format $PROJECT_ROOT/App.slnx --verify-no-changes --no-restore" "$DOTNET_LOG"
  grep -Fq "$PROJECT_ROOT|test $PROJECT_ROOT/App.slnx --no-build --no-restore" "$DOTNET_LOG"
}
