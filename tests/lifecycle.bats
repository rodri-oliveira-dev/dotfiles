#!/usr/bin/env bats

load test_helper

setup() {
  setup_dotfiles_test
  printf 'export USER_SETTING=preserved\n' >"$HOME/.bashrc"
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

  for script in "$REPO_ROOT"/bin/*; do
    [ "$(readlink "$HOME/.local/bin/$(basename "$script")")" = "$script" ]
  done
}

@test "dotfiles-doctor succeeds after installation" {
  run "$REPO_ROOT/install.sh"
  [ "$status" -eq 0 ]

  run "$HOME/.local/bin/dotfiles-doctor"
  [ "$status" -eq 0 ]
  assert_output_contains "Failures: 0"
  assert_output_contains "managed $HOME/.bashrc block is present exactly once"
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

  for script in "$REPO_ROOT"/bin/*; do
    [ ! -e "$HOME/.local/bin/$(basename "$script")" ]
  done
}
