#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/rodri-dotfiles"
LOCAL_BIN="$HOME/.local/bin"
BASHRC="$HOME/.bashrc"
MARKER_BEGIN="# >>> rodri-dotfiles >>>"

echo "Configuring development environment..."

mkdir -p "$CONFIG_DIR" "$LOCAL_BIN"

ln -sfn "$DOTFILES_DIR/shell/aliases.sh" "$CONFIG_DIR/aliases.sh"
ln -sfn "$DOTFILES_DIR/shell/dotnet.sh" "$CONFIG_DIR/dotnet.sh"
ln -sfn "$DOTFILES_DIR/shell/git.sh" "$CONFIG_DIR/git.sh"

touch "$BASHRC"

if ! grep -Fq "$MARKER_BEGIN" "$BASHRC"; then
  cat >> "$BASHRC" <<'EOF'

# >>> rodri-dotfiles >>>
source "$HOME/.config/rodri-dotfiles/aliases.sh"
source "$HOME/.config/rodri-dotfiles/dotnet.sh"
source "$HOME/.config/rodri-dotfiles/git.sh"

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# <<< rodri-dotfiles <<<
EOF
fi

GIT_CONFIG_FILE="$DOTFILES_DIR/git/config"

if ! git config --global --get-all include.path 2>/dev/null | grep -Fxq "$GIT_CONFIG_FILE"; then
  git config --global --add include.path "$GIT_CONFIG_FILE"
fi

for script in "$DOTFILES_DIR"/bin/*; do
  [[ -f "$script" ]] || continue

  chmod +x "$script"
  ln -sfn "$script" "$LOCAL_BIN/$(basename "$script")"
done

echo
echo "Development environment configured."
echo "Run 'source ~/.bashrc' or start a new shell."
