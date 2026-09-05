#!/usr/bin/env bash
set -euo pipefail

if ((EUID == 0)); then
  echo "Error: install.sh must not be run as root. Run it as your normal development user." >&2
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_DIR="$XDG_CONFIG_HOME/rodri-dotfiles"
LOCAL_BIN="$HOME/.local/bin"
BASHRC="$HOME/.bashrc"
MARKER_BEGIN="# >>> rodri-dotfiles >>>"

echo "Configuring development environment..."

mkdir -p "$CONFIG_DIR" "$LOCAL_BIN"

ln -sfn "$DOTFILES_DIR/shell/aliases.sh" "$CONFIG_DIR/aliases.sh"
ln -sfn "$DOTFILES_DIR/shell/dotnet.sh" "$CONFIG_DIR/dotnet.sh"
ln -sfn "$DOTFILES_DIR/shell/git.sh" "$CONFIG_DIR/git.sh"
ln -sfn "$DOTFILES_DIR/git/config" "$CONFIG_DIR/gitconfig"

touch "$BASHRC"

if ! grep -Fq "$MARKER_BEGIN" "$BASHRC"; then
  cat >>"$BASHRC" <<'EOF'

# >>> rodri-dotfiles >>>
DOTFILES_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rodri-dotfiles"

if [[ -r "$DOTFILES_CONFIG_DIR/aliases.sh" ]]; then
  source "$DOTFILES_CONFIG_DIR/aliases.sh"
fi

if [[ -r "$DOTFILES_CONFIG_DIR/dotnet.sh" ]]; then
  source "$DOTFILES_CONFIG_DIR/dotnet.sh"
fi

if [[ -r "$DOTFILES_CONFIG_DIR/git.sh" ]]; then
  source "$DOTFILES_CONFIG_DIR/git.sh"
fi

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

unset DOTFILES_CONFIG_DIR
# <<< rodri-dotfiles <<<
EOF
fi

LEGACY_GIT_CONFIG_FILE="$DOTFILES_DIR/git/config"
STABLE_GIT_CONFIG_FILE="$CONFIG_DIR/gitconfig"

# Migrate the original repository-relative include path, without touching unrelated includes.
git config --global --fixed-value --unset-all include.path "$LEGACY_GIT_CONFIG_FILE" 2>/dev/null || true

if ! git config --global --get-all include.path 2>/dev/null | grep -Fxq "$STABLE_GIT_CONFIG_FILE"; then
  git config --global --add include.path "$STABLE_GIT_CONFIG_FILE"
fi

if git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  chmod +x "$DOTFILES_DIR/.githooks/pre-commit"
  git -C "$DOTFILES_DIR" config --local core.hooksPath .githooks
fi

for script in "$DOTFILES_DIR"/bin/*; do
  [[ -f "$script" ]] || continue

  chmod +x "$script"
  ln -sfn "$script" "$LOCAL_BIN/$(basename "$script")"
done

echo
echo "Development environment configured."
echo "Run 'source ~/.bashrc' or start a new shell."
