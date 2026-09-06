#!/usr/bin/env bats

load test_helper

setup() {
  setup_dotfiles_test
  create_update_fixture
}

create_update_fixture() {
  TEST_REPO="$BATS_TEST_TMPDIR/dotfiles"
  REMOTE_REPO="$BATS_TEST_TMPDIR/dotfiles-remote.git"

  mkdir -p "$TEST_REPO"
  cp "$REPO_ROOT/install.sh" "$REPO_ROOT/uninstall.sh" "$TEST_REPO/"
  cp -R "$REPO_ROOT/bin" "$REPO_ROOT/git" "$REPO_ROOT/shell" "$REPO_ROOT/scripts" "$REPO_ROOT/.githooks" "$TEST_REPO/"
  printf 'initial\n' >"$TEST_REPO/fixture.txt"

  git init -q -b main "$TEST_REPO"
  git -C "$TEST_REPO" config user.name "Dotfiles Test"
  git -C "$TEST_REPO" config user.email "dotfiles-test@example.invalid"
  git -C "$TEST_REPO" add .
  git -C "$TEST_REPO" commit -qm "initial"

  git init --bare -q "$REMOTE_REPO"
  git -C "$TEST_REPO" remote add origin "$REMOTE_REPO"
  git -C "$TEST_REPO" push -qu -u origin main

  export TEST_REPO
  export REMOTE_REPO
}

@test "dotfiles-update refuses to run with uncommitted changes" {
  printf 'dirty\n' >>"$TEST_REPO/fixture.txt"

  run bash "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 1 ]
  assert_contains "$output" "contains uncommitted changes"
}

@test "dotfiles-update fast-forwards, reinstalls, and runs diagnostics" {
  PEER_REPO="$BATS_TEST_TMPDIR/peer"
  git clone -q --branch main "$REMOTE_REPO" "$PEER_REPO"
  git -C "$PEER_REPO" config user.name "Dotfiles Peer"
  git -C "$PEER_REPO" config user.email "dotfiles-peer@example.invalid"

  printf 'updated\n' >"$PEER_REPO/update-marker.txt"
  git -C "$PEER_REPO" add update-marker.txt
  git -C "$PEER_REPO" commit -qm "update fixture"
  git -C "$PEER_REPO" push -q origin main

  run bash "$TEST_REPO/bin/dotfiles-update"

  [ "$status" -eq 0 ]
  [ -f "$TEST_REPO/update-marker.txt" ]
  [ "$(git -C "$TEST_REPO" rev-parse HEAD)" = "$(git -C "$TEST_REPO" rev-parse origin/main)" ]
  [ "$(git -C "$TEST_REPO" config --local --get core.hooksPath)" = ".githooks" ]
  assert_contains "$output" "Dotfiles updated successfully."
  assert_contains "$output" "Failures: 0"
}
