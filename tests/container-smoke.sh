#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASHRC="$HOME/.bashrc"

cd "$REPO_ROOT"

printf 'export USER_SETTING=preserved\n' >"$BASHRC"

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
