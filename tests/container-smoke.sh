#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASHRC="$HOME/.bashrc"
UNMANAGED_BIN="$HOME/.local/bin/dotfiles-doctor"

cd "$REPO_ROOT"

printf 'export USER_SETTING=preserved\n' >"$BASHRC"
mkdir -p "$HOME/.local/bin"
printf 'external helper\n' >"$UNMANAGED_BIN"

if ./install.sh >/tmp/conflict-install.log 2>&1; then
  cat /tmp/conflict-install.log
  echo "install.sh unexpectedly replaced an unmanaged destination" >&2
  exit 1
fi

grep -Fq "refusing to replace unmanaged path" /tmp/conflict-install.log
[[ "$(cat "$UNMANAGED_BIN")" == "external helper" ]]
! grep -Fq '# >>> rodri-dotfiles >>>' "$BASHRC"
rm "$UNMANAGED_BIN"

./install.sh
./install.sh

[[ "$(grep -Fc '# >>> rodri-dotfiles >>>' "$BASHRC")" -eq 1 ]]
[[ "$(grep -Fc '# <<< rodri-dotfiles <<<' "$BASHRC")" -eq 1 ]]
[[ "$(git config --local --get core.hooksPath)" == ".githooks" ]]
[[ -x "$REPO_ROOT/.githooks/pre-commit" ]]

"$HOME/.local/bin/dotfiles-doctor"

./uninstall.sh

grep -Fq 'export USER_SETTING=preserved' "$BASHRC"

if grep -Fq '# >>> rodri-dotfiles >>>' "$BASHRC"; then
  printf 'Managed Bash block was not removed by uninstall.\n' >&2
  exit 1
fi

if git config --local --get core.hooksPath >/dev/null 2>&1; then
  printf 'Managed core.hooksPath was not removed by uninstall.\n' >&2
  exit 1
fi

printf 'Container lifecycle smoke test completed successfully.\n'
