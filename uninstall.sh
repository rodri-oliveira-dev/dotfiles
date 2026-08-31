#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_DIR="$XDG_CONFIG_HOME/rodri-dotfiles"
LOCAL_BIN="$HOME/.local/bin"
BASHRC="$HOME/.bashrc"
MARKER_BEGIN="# >>> rodri-dotfiles >>>"
MARKER_END="# <<< rodri-dotfiles <<<"
STABLE_GIT_CONFIG_FILE="$CONFIG_DIR/gitconfig"
LEGACY_GIT_CONFIG_FILE="$DOTFILES_DIR/git/config"

remove_managed_block() {
  local begin_count
  local end_count
  local temporary_file

  [[ -f "$BASHRC" ]] || return 0

  begin_count="$(grep -Fc "$MARKER_BEGIN" "$BASHRC" || true)"
  end_count="$(grep -Fc "$MARKER_END" "$BASHRC" || true)"

  if [[ "$begin_count" == "0" && "$end_count" == "0" ]]; then
    return 0
  fi

  if [[ "$begin_count" != "1" || "$end_count" != "1" ]]; then
    echo "Warning: managed ~/.bashrc markers are inconsistent; leaving ~/.bashrc unchanged." >&2
    return 0
  fi

  temporary_file="$(mktemp)"

  awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
    $0 == begin { skipping = 1; next }
    $0 == end   { skipping = 0; next }
    !skipping   { print }
  ' "$BASHRC" > "$temporary_file"

  cat "$temporary_file" > "$BASHRC"
  rm -f "$temporary_file"

  echo "Removed managed block from ~/.bashrc."
}

remove_managed_symlink() {
  local path="$1"
  local expected_target="$2"
  local actual_target

  [[ -e "$path" || -L "$path" ]] || return 0

  if [[ ! -L "$path" ]]; then
    echo "Warning: $path is not a symlink; leaving it unchanged." >&2
    return 0
  fi

  actual_target="$(readlink "$path")"

  if [[ "$actual_target" != "$expected_target" ]]; then
    echo "Warning: $path points to $actual_target; leaving it unchanged." >&2
    return 0
  fi

  rm "$path"
  echo "Removed $path."
}

echo "Removing managed dotfiles configuration..."

remove_managed_block

if command -v git >/dev/null 2>&1; then
  git config --global --fixed-value --unset-all include.path "$STABLE_GIT_CONFIG_FILE" 2>/dev/null || true
  git config --global --fixed-value --unset-all include.path "$LEGACY_GIT_CONFIG_FILE" 2>/dev/null || true
  echo "Removed managed Git include.path entries."
else
  echo "Warning: git is not available; Git include.path entries were not changed." >&2
fi

for script in "$DOTFILES_DIR"/bin/*; do
  [[ -f "$script" ]] || continue
  remove_managed_symlink "$LOCAL_BIN/$(basename "$script")" "$script"
done

remove_managed_symlink "$CONFIG_DIR/aliases.sh" "$DOTFILES_DIR/shell/aliases.sh"
remove_managed_symlink "$CONFIG_DIR/dotnet.sh" "$DOTFILES_DIR/shell/dotnet.sh"
remove_managed_symlink "$CONFIG_DIR/git.sh" "$DOTFILES_DIR/shell/git.sh"
remove_managed_symlink "$CONFIG_DIR/gitconfig" "$DOTFILES_DIR/git/config"

if [[ -d "$CONFIG_DIR" ]]; then
  if rmdir "$CONFIG_DIR" 2>/dev/null; then
    echo "Removed empty configuration directory $CONFIG_DIR."
  else
    echo "Keeping $CONFIG_DIR because it contains files not managed by this repository."
  fi
fi

echo
echo "Managed dotfiles configuration removed."
echo "Existing user files and unrelated Git/shell configuration were left intact."
