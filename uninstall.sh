#!/usr/bin/env bash
set -euo pipefail

if ((EUID == 0)); then
  echo "Error: uninstall.sh must not be run as root. Run it as your normal development user." >&2
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_DIR="$XDG_CONFIG_HOME/rodri-dotfiles"
LOCAL_BIN="$HOME/.local/bin"
BASHRC="$HOME/.bashrc"
MARKER_BEGIN="# >>> rodri-dotfiles >>>"
MARKER_END="# <<< rodri-dotfiles <<<"
STABLE_GIT_CONFIG_FILE="$CONFIG_DIR/gitconfig"
LEGACY_GIT_CONFIG_FILE="$DOTFILES_DIR/git/config"
BASHRC_TEMP_FILE=""

cleanup_bashrc_temp() {
  if [[ -n "$BASHRC_TEMP_FILE" ]]; then
    rm -f -- "$BASHRC_TEMP_FILE" || true
  fi
}

trap cleanup_bashrc_temp EXIT

validate_bashrc_file() {
  local path="$1"
  local display_path="${2:-$path}"
  local marker_state
  local begin_count
  local end_count
  local begin_line
  local end_line

  if [[ -L "$path" ]]; then
    echo "Error: refusing to modify symlinked Bash startup file: $display_path" >&2
    return 1
  fi

  if [[ -e "$path" && ! -f "$path" ]]; then
    echo "Error: refusing to modify non-regular Bash startup file: $display_path" >&2
    return 1
  fi

  [[ -e "$path" ]] || return 0

  marker_state="$(
    awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
      $0 == begin {
        begin_count++
        if (begin_line == 0) begin_line = NR
      }
      $0 == end {
        end_count++
        if (end_line == 0) end_line = NR
      }
      END {
        printf "%d %d %d %d\n", begin_count, end_count, begin_line, end_line
      }
    ' "$path"
  )"
  read -r begin_count end_count begin_line end_line <<<"$marker_state"

  if [[ "$begin_count" == "0" && "$end_count" == "0" ]]; then
    return 0
  fi

  if [[ "$begin_count" != "1" || "$end_count" != "1" ]]; then
    echo "Error: managed Bash markers are inconsistent in $display_path (begin=$begin_count, end=$end_count)." >&2
    return 1
  fi

  if ((begin_line >= end_line)); then
    echo "Error: managed Bash markers are out of order in $display_path." >&2
    return 1
  fi
}

remove_managed_block() {
  local bashrc_dir

  if [[ ! -e "$BASHRC" && ! -L "$BASHRC" ]]; then
    return 0
  fi

  validate_bashrc_file "$BASHRC"

  if ! grep -Fxq "$MARKER_BEGIN" "$BASHRC"; then
    return 0
  fi

  bashrc_dir="$(dirname "$BASHRC")"

  if ! BASHRC_TEMP_FILE="$(mktemp "$bashrc_dir/.bashrc.rodri-dotfiles.XXXXXX")"; then
    echo "Error: failed to create temporary Bash startup file beside $BASHRC." >&2
    return 1
  fi

  if ! cp -p -- "$BASHRC" "$BASHRC_TEMP_FILE"; then
    echo "Error: failed to copy $BASHRC before updating it; original file was left unchanged." >&2
    return 1
  fi

  if ! awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
    $0 == begin { skipping = 1; next }
    $0 == end   { skipping = 0; next }
    !skipping   { print }
  ' "$BASHRC" >"$BASHRC_TEMP_FILE"; then
    echo "Error: failed to build updated Bash startup file; $BASHRC was left unchanged." >&2
    return 1
  fi

  if ! validate_bashrc_file "$BASHRC_TEMP_FILE" "temporary Bash startup file for $BASHRC"; then
    echo "Error: refusing to replace $BASHRC because the generated file failed validation." >&2
    return 1
  fi

  if grep -Fxq "$MARKER_BEGIN" "$BASHRC_TEMP_FILE" || grep -Fxq "$MARKER_END" "$BASHRC_TEMP_FILE"; then
    echo "Error: managed Bash markers remain after removal; $BASHRC was left unchanged." >&2
    return 1
  fi

  if ! mv -- "$BASHRC_TEMP_FILE" "$BASHRC"; then
    echo "Error: failed to atomically replace $BASHRC; original file was left unchanged." >&2
    return 1
  fi

  BASHRC_TEMP_FILE=""
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

  if git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CURRENT_HOOKS_PATH="$(git -C "$DOTFILES_DIR" config --local --get core.hooksPath 2>/dev/null || true)"

    if [[ "$CURRENT_HOOKS_PATH" == ".githooks" ]]; then
      git -C "$DOTFILES_DIR" config --local --unset core.hooksPath
      echo "Removed managed repository hooks path."
    fi
  fi
else
  echo "Warning: git is not available; Git configuration was not changed." >&2
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
