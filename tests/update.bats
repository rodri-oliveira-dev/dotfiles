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

  mkdir -p "$SEED_REPO"
  cp "$REPO_ROOT/install.sh" "$REPO_ROOT/uninstall.sh" "$SEED_REPO/"
  cp -R "$REPO_ROOT/bin" "$REPO_ROOT/git" "$REPO_ROOT/shell" "$REPO_ROOT/scripts" "$REPO_ROOT/.githooks" "$SEED_REPO/"
  printf 'initial\n' >"$SEED_REPO/fixture.txt"

  git init -q -b main "$SEED_REPO"
  git -C "$SEED_REPO" config user.name "Dotfiles Test"
  git -C "$SEED_REPO" config user.email "dotfiles-test@example.invalid"
  git -C "$SEED_REPO" config core.filemode true
  git -C "$SEED_REPO" add .
  git -C "$SEED_REPO" commit -qm "initial"

  git init --bare -q "$REMOTE_REPO"
  git -C "$SEED_REPO" remote add origin "$REMOTE_REPO"
  git -C "$SEED_REPO" push -qu -u origin main

  git clone -q --branch main "$REMOTE_REPO" "$TEST_REPO"
  git -C "$TEST_REPO" config user.name "Dotfiles Test"
  git -C "$TEST_REPO" config user.email "dotfiles-test@example.invalid"
  git -C "$TEST_REPO" config core.filemode true

  export SEED_REPO
  export TEST_REPO
  export REMOTE_REPO
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
}

@test "dotfiles-update refuses detached HEAD" {
  git -C "$TEST_REPO" checkout -q --detach

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 1 ]
  assert_contains "$output" "detached HEAD state"
}

@test "dotfiles-update fast-forwards, reinstalls, and runs diagnostics" {
  run "$TEST_REPO/install.sh"
  [ "$status" -eq 0 ]
  [ -z "$(git -C "$TEST_REPO" status --porcelain)" ]

  PEER_REPO="$BATS_TEST_TMPDIR/peer"
  git clone -q --branch main "$REMOTE_REPO" "$PEER_REPO"
  git -C "$PEER_REPO" config user.name "Dotfiles Peer"
  git -C "$PEER_REPO" config user.email "dotfiles-peer@example.invalid"

  printf 'updated\n' >"$PEER_REPO/update-marker.txt"
  git -C "$PEER_REPO" add update-marker.txt
  git -C "$PEER_REPO" commit -qm "update fixture"
  git -C "$PEER_REPO" push -q origin main

  run "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 0 ]
  [ -f "$TEST_REPO/update-marker.txt" ]
  [ "$(git -C "$TEST_REPO" rev-parse HEAD)" = "$(git -C "$TEST_REPO" rev-parse origin/main)" ]
  [ "$(git -C "$TEST_REPO" config --local --get core.hooksPath)" = ".githooks" ]
  [ -z "$(git -C "$TEST_REPO" status --porcelain)" ]
  assert_contains "$output" "Dotfiles updated successfully."
  assert_contains "$output" "Failures: 0"

  run "$HOME/.local/bin/dotfiles-doctor"
  [ "$status" -eq 0 ]
  assert_contains "$output" "Failures: 0"
}
