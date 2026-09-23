#!/usr/bin/env bats

load test_helper

setup() {
  setup_dotfiles_test
  printf 'export USER_SETTING=preserved\n' >"$HOME/.bashrc"

  ORIGINAL_HOOKS_PATH_SET=false
  ORIGINAL_HOOKS_PATH=""

  if ORIGINAL_HOOKS_PATH="$(git -C "$REPO_ROOT" config --local --get core.hooksPath 2>/dev/null)"; then
    ORIGINAL_HOOKS_PATH_SET=true
  fi
}

teardown() {
  if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$REPO_ROOT" config --local --unset-all core.hooksPath >/dev/null 2>&1 || true

    if [[ "$ORIGINAL_HOOKS_PATH_SET" == "true" ]]; then
      git -C "$REPO_ROOT" config --local core.hooksPath "$ORIGINAL_HOOKS_PATH"
    fi
  fi
}

assert_no_install_configuration_mutation() {
  grep -Fq 'export USER_SETTING=preserved' "$HOME/.bashrc"
  ! grep -Fq '# >>> rodri-dotfiles >>>' "$HOME/.bashrc"
  ! grep -Fq '# <<< rodri-dotfiles <<<' "$HOME/.bashrc"

  if git config --global --get-all include.path >"$BATS_TEST_TMPDIR/include-paths" 2>/dev/null; then
    ! grep -Fxq "$XDG_CONFIG_HOME/rodri-dotfiles/gitconfig" "$BATS_TEST_TMPDIR/include-paths"
  fi
}

assert_no_managed_git_include() {
  if git config --global --get-all include.path >"$BATS_TEST_TMPDIR/include-paths" 2>/dev/null; then
    ! grep -Fxq "$XDG_CONFIG_HOME/rodri-dotfiles/gitconfig" "$BATS_TEST_TMPDIR/include-paths"
  fi
}

@test "install is idempotent and creates stable managed links" {
  run "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]

  run "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]

  [ "$(grep -Fc '# >>> rodri-dotfiles >>>' "$HOME/.bashrc")" -eq 1 ]
  [ "$(grep -Fc '# <<< rodri-dotfiles <<<' "$HOME/.bashrc")" -eq 1 ]
  [ "$(grep -Fc 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc")" -eq 1 ]

  [ "$(readlink "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh")" = "$REPO_ROOT/shell/aliases.sh" ]
  [ "$(readlink "$XDG_CONFIG_HOME/rodri-dotfiles/dotnet.sh")" = "$REPO_ROOT/shell/dotnet.sh" ]
  [ "$(readlink "$XDG_CONFIG_HOME/rodri-dotfiles/git.sh")" = "$REPO_ROOT/shell/git.sh" ]
  [ "$(readlink "$XDG_CONFIG_HOME/rodri-dotfiles/gitconfig")" = "$REPO_ROOT/git/config" ]

  [ "$(git config --global --get-all include.path | grep -Fxc "$XDG_CONFIG_HOME/rodri-dotfiles/gitconfig")" -eq 1 ]
  [ "$(git -C "$REPO_ROOT" config --local --get core.hooksPath)" = ".githooks" ]
  [ -x "$REPO_ROOT/.githooks/pre-commit" ]

  for script in "$REPO_ROOT"/bin/*; do
    [ "$(readlink "$HOME/.local/bin/$(basename "$script")")" = "$script" ]
  done
}

@test "install accepts an existing symlink only when it already points to the managed target" {
  mkdir -p "$XDG_CONFIG_HOME/rodri-dotfiles"
  ln -s "$REPO_ROOT/shell/aliases.sh" "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh"

  run "$REPO_ROOT/install.sh"

  [ "$status" -eq 0 ]
  [ "$(readlink "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh")" = "$REPO_ROOT/shell/aliases.sh" ]
}

@test "install refuses a missing managed target before changing configuration" {
  incomplete_repo="$BATS_TEST_TMPDIR/incomplete-dotfiles"
  mkdir -p "$incomplete_repo"
  cp "$REPO_ROOT/install.sh" "$REPO_ROOT/uninstall.sh" "$incomplete_repo/"
  cp -R "$REPO_ROOT/bin" "$REPO_ROOT/git" "$REPO_ROOT/shell" "$REPO_ROOT/.githooks" "$incomplete_repo/"
  rm "$incomplete_repo/shell/aliases.sh"

  run bash "$incomplete_repo/install.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "missing managed target"
  assert_contains "$output" "$incomplete_repo/shell/aliases.sh"
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh" ]
  assert_no_install_configuration_mutation
}

@test "install fails safely if a directory appears at a validated destination before link creation" {
  fake_bin="$BATS_TEST_TMPDIR/fake-ln-bin"
  race_marker="$BATS_TEST_TMPDIR/ln-race-triggered"
  real_ln="$(command -v ln)"
  mkdir -p "$fake_bin"

  cat >"$fake_bin/ln" <<EOF
#!/usr/bin/env bash
set -euo pipefail

destination="\${@: -1}"

if [[ "\$destination" == "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh" ]]; then
  : >"$race_marker"
  mkdir -p "\$destination"
fi

exec "$real_ln" "\$@"
EOF
  chmod +x "$fake_bin/ln"

  PATH="$fake_bin:$PATH" run "$REPO_ROOT/install.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "failed to create managed symlink"
  [ -f "$race_marker" ]
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh/aliases.sh" ]
  assert_no_install_configuration_mutation
}

@test "install refuses an unmanaged configuration file before changing shell or Git configuration" {
  mkdir -p "$XDG_CONFIG_HOME/rodri-dotfiles"
  printf 'external configuration\n' >"$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh"

  run "$REPO_ROOT/install.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "refusing to replace unmanaged path"
  assert_contains "$output" "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh"
  [ "$(cat "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh")" = "external configuration" ]
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/dotnet.sh" ]
  assert_no_install_configuration_mutation
}

@test "install refuses an unmanaged bin directory without deleting its contents" {
  mkdir -p "$HOME/.local/bin/dotfiles-doctor"
  printf 'keep-me\n' >"$HOME/.local/bin/dotfiles-doctor/sentinel.txt"

  run "$REPO_ROOT/install.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "refusing to replace unmanaged path"
  assert_contains "$output" "$HOME/.local/bin/dotfiles-doctor"
  [ "$(cat "$HOME/.local/bin/dotfiles-doctor/sentinel.txt")" = "keep-me" ]
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh" ]
  assert_no_install_configuration_mutation
}

@test "install refuses a broken unmanaged symlink and preserves its target text" {
  mkdir -p "$XDG_CONFIG_HOME/rodri-dotfiles"
  broken_target="$HOME/missing external target"
  ln -s "$broken_target" "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh"

  run "$REPO_ROOT/install.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "refusing to replace unmanaged symlink"
  assert_contains "$output" "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh"
  [ "$(readlink "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh")" = "$broken_target" ]
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/dotnet.sh" ]
  assert_no_install_configuration_mutation
}

@test "install supports custom XDG paths and managed filenames containing spaces" {
  spaced_repo="$BATS_TEST_TMPDIR/dotfiles repo"
  mkdir -p "$spaced_repo"
  cp "$REPO_ROOT/install.sh" "$REPO_ROOT/uninstall.sh" "$spaced_repo/"
  cp -R "$REPO_ROOT/bin" "$REPO_ROOT/git" "$REPO_ROOT/shell" "$REPO_ROOT/.githooks" "$spaced_repo/"

  cat >"$spaced_repo/bin/helper with space" <<'EOF'
#!/usr/bin/env bash
printf 'ok\n'
EOF
  chmod +x "$spaced_repo/bin/helper with space"

  export XDG_CONFIG_HOME="$HOME/custom config"

  run bash "$spaced_repo/install.sh"

  [ "$status" -eq 0 ]
  [ "$(readlink "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh")" = "$spaced_repo/shell/aliases.sh" ]
  [ "$(readlink "$HOME/.local/bin/helper with space")" = "$spaced_repo/bin/helper with space" ]

  run bash "$spaced_repo/install.sh"
  [ "$status" -eq 0 ]
}

@test "install refuses inverted managed Bash markers before changing managed state" {
  cat >"$HOME/.bashrc" <<'EOF'
export USER_SETTING=preserved
# <<< rodri-dotfiles <<<
echo keep-this
# >>> rodri-dotfiles >>>
EOF
  cp "$HOME/.bashrc" "$BATS_TEST_TMPDIR/bashrc-before"

  run "$REPO_ROOT/install.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "managed Bash markers are out of order"
  cmp -s "$BATS_TEST_TMPDIR/bashrc-before" "$HOME/.bashrc"
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh" ]
  assert_no_managed_git_include
}

@test "install refuses missing or duplicate exact Bash markers without truncating bashrc" {
  cat >"$HOME/.bashrc" <<'EOF'
export USER_SETTING=preserved
# >>> rodri-dotfiles >>>
echo keep-this
EOF
  cp "$HOME/.bashrc" "$BATS_TEST_TMPDIR/bashrc-missing-before"

  run "$REPO_ROOT/install.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "managed Bash markers are inconsistent"
  cmp -s "$BATS_TEST_TMPDIR/bashrc-missing-before" "$HOME/.bashrc"
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh" ]
  assert_no_managed_git_include

  cat >"$HOME/.bashrc" <<'EOF'
export USER_SETTING=preserved
# >>> rodri-dotfiles >>>
echo first
# <<< rodri-dotfiles <<<
# >>> rodri-dotfiles >>>
echo second
# <<< rodri-dotfiles <<<
EOF
  cp "$HOME/.bashrc" "$BATS_TEST_TMPDIR/bashrc-duplicate-before"

  run "$REPO_ROOT/install.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "managed Bash markers are inconsistent"
  cmp -s "$BATS_TEST_TMPDIR/bashrc-duplicate-before" "$HOME/.bashrc"
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh" ]
  assert_no_managed_git_include
}

@test "marker text inside other comments is not treated as a managed marker" {
  cat >"$HOME/.bashrc" <<'EOF'
export USER_SETTING=preserved
# Documentation example: # >>> rodri-dotfiles >>>
# Documentation example: # <<< rodri-dotfiles <<<
EOF

  run "$REPO_ROOT/install.sh"

  [ "$status" -eq 0 ]
  [ "$(grep -Fxc '# >>> rodri-dotfiles >>>' "$HOME/.bashrc")" -eq 1 ]
  [ "$(grep -Fxc '# <<< rodri-dotfiles <<<' "$HOME/.bashrc")" -eq 1 ]
  grep -Fq '# Documentation example: # >>> rodri-dotfiles >>>' "$HOME/.bashrc"

  run "$REPO_ROOT/uninstall.sh"

  [ "$status" -eq 0 ]
  grep -Fq '# Documentation example: # >>> rodri-dotfiles >>>' "$HOME/.bashrc"
  grep -Fq '# Documentation example: # <<< rodri-dotfiles <<<' "$HOME/.bashrc"
  ! grep -Fxq '# >>> rodri-dotfiles >>>' "$HOME/.bashrc"
  ! grep -Fxq '# <<< rodri-dotfiles <<<' "$HOME/.bashrc"
}

@test "install refuses symlinked and non-regular bashrc paths" {
  external_bashrc="$BATS_TEST_TMPDIR/external bashrc"
  printf 'external-content\n' >"$external_bashrc"
  rm "$HOME/.bashrc"
  ln -s "$external_bashrc" "$HOME/.bashrc"

  run "$REPO_ROOT/install.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "refusing to modify symlinked Bash startup file"
  [ "$(cat "$external_bashrc")" = "external-content" ]
  [ "$(readlink "$HOME/.bashrc")" = "$external_bashrc" ]
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh" ]

  rm "$HOME/.bashrc"
  mkdir "$HOME/.bashrc"

  run "$REPO_ROOT/install.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "refusing to modify non-regular Bash startup file"
  [ -d "$HOME/.bashrc" ]
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh" ]
}

@test "uninstall refuses a symlinked bashrc before removing other managed state" {
  run "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]

  external_bashrc="$BATS_TEST_TMPDIR/external bashrc"
  printf 'external-content\n' >"$external_bashrc"
  rm "$HOME/.bashrc"
  ln -s "$external_bashrc" "$HOME/.bashrc"

  run "$REPO_ROOT/uninstall.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "refusing to modify symlinked Bash startup file"
  [ "$(cat "$external_bashrc")" = "external-content" ]
  [ -L "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh" ]
  git config --global --get-all include.path | grep -Fxq "$XDG_CONFIG_HOME/rodri-dotfiles/gitconfig"
}

@test "install and uninstall preserve bashrc permissions" {
  chmod 640 "$HOME/.bashrc"

  run "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]
  [ "$(stat -c '%a' "$HOME/.bashrc")" = "640" ]

  run "$REPO_ROOT/uninstall.sh"
  [ "$status" -eq 0 ]
  [ "$(stat -c '%a' "$HOME/.bashrc")" = "640" ]
  grep -Fq 'export USER_SETTING=preserved' "$HOME/.bashrc"
}

@test "bashrc lifecycle supports a missing file and HOME paths with spaces" {
  export HOME="$BATS_TEST_TMPDIR/home with space"
  export XDG_CONFIG_HOME="$HOME/custom config"
  export PATH="$HOME/.local/bin:$ORIGINAL_PATH"
  mkdir -p "$HOME"

  run "$REPO_ROOT/install.sh"

  [ "$status" -eq 0 ]
  [ -f "$HOME/.bashrc" ]
  [ "$(grep -Fxc '# >>> rodri-dotfiles >>>' "$HOME/.bashrc")" -eq 1 ]
  [ "$(grep -Fxc '# <<< rodri-dotfiles <<<' "$HOME/.bashrc")" -eq 1 ]

  run "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]
  [ "$(grep -Fxc '# >>> rodri-dotfiles >>>' "$HOME/.bashrc")" -eq 1 ]

  run "$REPO_ROOT/uninstall.sh"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.bashrc" ]
  ! grep -Fxq '# >>> rodri-dotfiles >>>' "$HOME/.bashrc"
}

@test "failed install rename preserves bashrc and cleans the temporary file" {
  fake_bin="$BATS_TEST_TMPDIR/fake-mv-bin"
  real_mv="$(command -v mv)"
  mkdir -p "$fake_bin"
  cp "$HOME/.bashrc" "$BATS_TEST_TMPDIR/bashrc-before"

  cat >"$fake_bin/mv" <<EOF
#!/usr/bin/env bash
set -euo pipefail

destination="\${@: -1}"
if [[ "\$destination" == "$HOME/.bashrc" ]]; then
  exit 73
fi
exec "$real_mv" "\$@"
EOF
  chmod +x "$fake_bin/mv"

  PATH="$fake_bin:$PATH" run "$REPO_ROOT/install.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "failed to atomically replace $HOME/.bashrc"
  cmp -s "$BATS_TEST_TMPDIR/bashrc-before" "$HOME/.bashrc"
  shopt -s nullglob
  leftovers=("$HOME"/.bashrc.rodri-dotfiles.*)
  [ "${#leftovers[@]}" -eq 0 ]
}

@test "failed uninstall rename preserves bashrc and managed state and cleans the temporary file" {
  run "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]
  cp "$HOME/.bashrc" "$BATS_TEST_TMPDIR/bashrc-before-uninstall"

  fake_bin="$BATS_TEST_TMPDIR/fake-uninstall-mv-bin"
  real_mv="$(command -v mv)"
  mkdir -p "$fake_bin"

  cat >"$fake_bin/mv" <<EOF
#!/usr/bin/env bash
set -euo pipefail

destination="\${@: -1}"
if [[ "\$destination" == "$HOME/.bashrc" ]]; then
  exit 74
fi
exec "$real_mv" "\$@"
EOF
  chmod +x "$fake_bin/mv"

  PATH="$fake_bin:$PATH" run "$REPO_ROOT/uninstall.sh"

  [ "$status" -ne 0 ]
  assert_contains "$output" "failed to atomically replace $HOME/.bashrc"
  cmp -s "$BATS_TEST_TMPDIR/bashrc-before-uninstall" "$HOME/.bashrc"
  [ -L "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh" ]
  git config --global --get-all include.path | grep -Fxq "$XDG_CONFIG_HOME/rodri-dotfiles/gitconfig"
  shopt -s nullglob
  leftovers=("$HOME"/.bashrc.rodri-dotfiles.*)
  [ "${#leftovers[@]}" -eq 0 ]
}

@test "dotfiles-doctor succeeds after installation" {
  run "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]

  run "$HOME/.local/bin/dotfiles-doctor"
  [ "$status" -eq 0 ]
  assert_contains "$output" "Failures: 0"
  assert_contains "$output" "managed $HOME/.bashrc block is present exactly once"
  assert_contains "$output" "repository core.hooksPath uses .githooks"
}

@test "uninstall removes only repository-managed state" {
  git config --global --add include.path "$HOME/custom-gitconfig"

  run "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]

  printf 'keep-me\n' >"$XDG_CONFIG_HOME/rodri-dotfiles/custom.txt"

  run "$REPO_ROOT/uninstall.sh"
  [ "$status" -eq 0 ]

  grep -Fq 'export USER_SETTING=preserved' "$HOME/.bashrc"
  ! grep -Fq '# >>> rodri-dotfiles >>>' "$HOME/.bashrc"
  ! grep -Fq '# <<< rodri-dotfiles <<<' "$HOME/.bashrc"

  [ -f "$XDG_CONFIG_HOME/rodri-dotfiles/custom.txt" ]
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/aliases.sh" ]
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/dotnet.sh" ]
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/git.sh" ]
  [ ! -e "$XDG_CONFIG_HOME/rodri-dotfiles/gitconfig" ]

  git config --global --get-all include.path | grep -Fxq "$HOME/custom-gitconfig"
  ! git config --global --get-all include.path | grep -Fxq "$XDG_CONFIG_HOME/rodri-dotfiles/gitconfig"
  ! git -C "$REPO_ROOT" config --local --get core.hooksPath >/dev/null 2>&1

  for script in "$REPO_ROOT"/bin/*; do
    [ ! -e "$HOME/.local/bin/$(basename "$script")" ]
  done
}
