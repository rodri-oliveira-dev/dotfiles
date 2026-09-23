#!/usr/bin/env bats

load test_helper

setup() {
  setup_dotfiles_test
  create_update_fixture
}

create_update_fixture() {
  SEED_REPO="$BATS_TEST_TMPDIR/dotfiles-seed"
  TEST_REPO="$BATS_TEST_TMPDIR/dotfiles"
  REMOTE_REPO="$BATS_TEST_TMPDIR/dotfiles-remote.git"
  GIT_SHIM_DIR="$BATS_TEST_TMPDIR/git-shim"
  GIT_SHIM_LOG="$BATS_TEST_TMPDIR/git-shim.log"
  OFFICIAL_REMOTE_URL="https://github.com/rodri-oliveira-dev/dotfiles.git"
  REAL_GIT="$(command -v git)"

  mkdir -p "$SEED_REPO"
  cp "$REPO_ROOT/install.sh" "$REPO_ROOT/uninstall.sh" "$SEED_REPO/"
  cp -R "$REPO_ROOT/bin" "$REPO_ROOT/lib" "$REPO_ROOT/git" "$REPO_ROOT/shell" "$REPO_ROOT/scripts" "$REPO_ROOT/.githooks" "$SEED_REPO/"
  printf 'initial\n' >"$SEED_REPO/fixture.txt"

  "$REAL_GIT" init -q -b main "$SEED_REPO"
  "$REAL_GIT" -C "$SEED_REPO" config user.name "Dotfiles Test"
  "$REAL_GIT" -C "$SEED_REPO" config user.email "dotfiles-test@example.invalid"
  "$REAL_GIT" -C "$SEED_REPO" config core.filemode true
  "$REAL_GIT" -C "$SEED_REPO" add .
  "$REAL_GIT" -C "$SEED_REPO" commit -qm "initial"

  "$REAL_GIT" init --bare -q "$REMOTE_REPO"
  "$REAL_GIT" -C "$SEED_REPO" push -q "$REMOTE_REPO" main

  "$REAL_GIT" clone -q --branch main "$REMOTE_REPO" "$TEST_REPO"
  "$REAL_GIT" -C "$TEST_REPO" config user.name "Dotfiles Test"
  "$REAL_GIT" -C "$TEST_REPO" config user.email "dotfiles-test@example.invalid"
  "$REAL_GIT" -C "$TEST_REPO" config core.filemode true
  "$REAL_GIT" -C "$TEST_REPO" remote set-url origin "$OFFICIAL_REMOTE_URL"

  mkdir -p "$GIT_SHIM_DIR"
  : >"$GIT_SHIM_LOG"

  cat >"$GIT_SHIM_DIR/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"${GIT_SHIM_LOG:?}"

if [[ "$*" == *"fetch --prune origin main"* ]]; then
  exec "${REAL_GIT:?}" -C "${TEST_REPO:?}" -c core.hooksPath=/dev/null \
    fetch --prune "${REMOTE_REPO:?}" \
    "refs/heads/main:refs/remotes/origin/main"
fi

exec "${REAL_GIT:?}" "$@"
EOF
  chmod +x "$GIT_SHIM_DIR/git"

  export SEED_REPO
  export TEST_REPO
  export REMOTE_REPO
  export GIT_SHIM_DIR
  export GIT_SHIM_LOG
  export OFFICIAL_REMOTE_URL
  export REAL_GIT
  export PATH="$GIT_SHIM_DIR:$PATH"
}

push_remote_change() {
  local peer_repo="$BATS_TEST_TMPDIR/peer-$RANDOM"

  "$REAL_GIT" clone -q --branch main "$REMOTE_REPO" "$peer_repo"
  "$REAL_GIT" -C "$peer_repo" config user.name "Dotfiles Peer"
  "$REAL_GIT" -C "$peer_repo" config user.email "dotfiles-peer@example.invalid"

  printf '%s\n' "${1:-updated}" >"$peer_repo/update-marker.txt"
  "$REAL_GIT" -C "$peer_repo" add update-marker.txt
  "$REAL_GIT" -C "$peer_repo" commit -qm "update fixture"
  "$REAL_GIT" -C "$peer_repo" push -q origin main
}

@test "directly invoked scripts are tracked as executable" {
  [ "$(git -C "$TEST_REPO" ls-files -s .githooks/pre-commit | awk '{print $1}')" = "100755" ]
  [ "$(git -C "$TEST_REPO" ls-files -s bin/dotfiles-update | awk '{print $1}')" = "100755" ]
  [ -x "$TEST_REPO/.githooks/pre-commit" ]
  [ -x "$TEST_REPO/bin/dotfiles-update" ]
}

@test "install and reinstall keep worktree clean with core.filemode=true" {
  run "$TEST_REPO/install.sh"
  [ "$status" -eq 0 ]

  run git -C "$TEST_REPO" status --porcelain
  [ "$status" -eq 0 ]
  [ -z "$output" ]

  run "$TEST_REPO/install.sh"
  [ "$status" -eq 0 ]

  run git -C "$TEST_REPO" status --porcelain
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "dotfiles-update refuses to run with uncommitted changes" {
  printf 'dirty\n' >>"$TEST_REPO/fixture.txt"

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 1 ]
  assert_contains "$output" "contains uncommitted changes"
  ! grep -Fq "fetch --prune origin main" "$GIT_SHIM_LOG"
}

@test "dotfiles-update refuses detached HEAD" {
  git -C "$TEST_REPO" checkout -q --detach

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 1 ]
  assert_contains "$output" "detached HEAD state"
  ! grep -Fq "fetch --prune origin main" "$GIT_SHIM_LOG"
}

@test "dotfiles-update refuses non-distribution branches" {
  git -C "$TEST_REPO" checkout -qb feature/local

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 1 ]
  assert_contains "$output" "allowed only from the main distribution branch"
  ! grep -Fq "fetch --prune origin main" "$GIT_SHIM_LOG"
}

@test "dotfiles-update refuses an unexpected upstream" {
  git -C "$TEST_REPO" update-ref refs/remotes/origin/other HEAD
  git -C "$TEST_REPO" branch --set-upstream-to=origin/other main >/dev/null

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 1 ]
  assert_contains "$output" "must track origin/main"
  ! grep -Fq "fetch --prune origin main" "$GIT_SHIM_LOG"
}

@test "dotfiles-update refuses an unauthorized remote" {
  git -C "$TEST_REPO" remote set-url origin "https://github.com/example/dotfiles.git"

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 1 ]
  assert_contains "$output" "does not point to an authorized dotfiles source"
  ! grep -Fq "fetch --prune origin main" "$GIT_SHIM_LOG"
}

@test "dotfiles-update refuses remote URL rewriting" {
  git -C "$TEST_REPO" config url.https://mirror.invalid/dotfiles.git.insteadOf "$OFFICIAL_REMOTE_URL"

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 1 ]
  assert_contains "$output" "effective origin URL is not authorized"
  ! grep -Fq "fetch --prune origin main" "$GIT_SHIM_LOG"
}

@test "dotfiles-update accepts the official SSH remote form" {
  git -C "$TEST_REPO" remote set-url origin "git@github.com:rodri-oliveira-dev/dotfiles.git"

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 0 ]
  assert_contains "$output" "Dotfiles updated successfully."
}

@test "dotfiles-update refuses a local revision not authorized by origin main" {
  printf 'local-only\n' >"$TEST_REPO/local-only.txt"
  git -C "$TEST_REPO" add local-only.txt
  git -C "$TEST_REPO" commit -qm "local only"

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 1 ]
  assert_contains "$output" "is not a fast-forward from the current revision"
  [ ! -e "$HOME/.local/bin/dotfiles-doctor" ]
}

@test "dotfiles-update fast-forwards validated origin main without running merge hooks" {
  run "$TEST_REPO/install.sh"
  [ "$status" -eq 0 ]
  [ -z "$(git -C "$TEST_REPO" status --porcelain)" ]

  HOOK_DIR="$BATS_TEST_TMPDIR/untrusted-hooks"
  HOOK_MARKER="$BATS_TEST_TMPDIR/post-merge-ran"
  mkdir -p "$HOOK_DIR"
  cat >"$HOOK_DIR/post-merge" <<EOF
#!/usr/bin/env bash
touch "$HOOK_MARKER"
EOF
  chmod +x "$HOOK_DIR/post-merge"
  git -C "$TEST_REPO" config core.hooksPath "$HOOK_DIR"

  push_remote_change "updated"

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 0 ]
  [ -f "$TEST_REPO/update-marker.txt" ]
  [ ! -e "$HOOK_MARKER" ]
  [ "$(git -C "$TEST_REPO" rev-parse HEAD)" = "$(git -C "$TEST_REPO" rev-parse origin/main)" ]
  [ "$(git -C "$TEST_REPO" config --local --get core.hooksPath)" = ".githooks" ]
  [ -z "$(git -C "$TEST_REPO" status --porcelain)" ]
  assert_contains "$output" "Applying validated fast-forward update"
  assert_contains "$output" "Dotfiles updated successfully."
  assert_contains "$output" "Failures: 0"

  run "$HOME/.local/bin/dotfiles-doctor"
  [ "$status" -eq 0 ]
  assert_contains "$output" "Failures: 0"
}

@test "dotfiles-update preserves installer failure status after validated fast-forward" {
  PEER_REPO="$BATS_TEST_TMPDIR/failing-peer"
  "$REAL_GIT" clone -q --branch main "$REMOTE_REPO" "$PEER_REPO"
  "$REAL_GIT" -C "$PEER_REPO" config user.name "Dotfiles Peer"
  "$REAL_GIT" -C "$PEER_REPO" config user.email "dotfiles-peer@example.invalid"

  cat >"$PEER_REPO/install.sh" <<'EOF'
#!/usr/bin/env bash
echo "fixture installer failure" >&2
exit 23
EOF
  chmod +x "$PEER_REPO/install.sh"
  "$REAL_GIT" -C "$PEER_REPO" add install.sh
  "$REAL_GIT" -C "$PEER_REPO" commit -qm "failing installer fixture"
  "$REAL_GIT" -C "$PEER_REPO" push -q origin main

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 23 ]
  assert_contains "$output" "fixture installer failure"
  assert_contains "$output" "diagnostics were not run"
  [ "$(git -C "$TEST_REPO" rev-parse HEAD)" = "$(git -C "$TEST_REPO" rev-parse origin/main)" ]
  [ ! -e "$HOME/.local/bin/dotfiles-doctor" ]
}
