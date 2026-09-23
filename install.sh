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
MARKER_END="# <<< rodri-dotfiles <<<"
BASHRC_TEMP_FILE=""

declare -a MANAGED_LINK_TARGETS=()
declare -a MANAGED_LINK_DESTINATIONS=()

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
        printf "%d %d %d %d\\n", begin_count, end_count, begin_line, end_line
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

ensure_managed_bashrc() {
  local bashrc_dir

  if [[ -e "$BASHRC" ]] && grep -Fxq "$MARKER_BEGIN" "$BASHRC"; then
    return 0
  fi

  bashrc_dir="$(dirname "$BASHRC")"

  if ! BASHRC_TEMP_FILE="$(mktemp "$bashrc_dir/.bashrc.rodri-dotfiles.XXXXXX")"; then
    echo "Error: failed to create temporary Bash startup file beside $BASHRC." >&2
    return 1
  fi

  if [[ -e "$BASHRC" ]] && ! cp -p -- "$BASHRC" "$BASHRC_TEMP_FILE"; then
    echo "Error: failed to copy $BASHRC before updating it; original file was left unchanged." >&2
    return 1
  fi

  if ! cat >>"$BASHRC_TEMP_FILE" <<'EOF'

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
  then
    echo "Error: failed to write temporary Bash startup file; $BASHRC was left unchanged." >&2
    return 1
  fi

  if ! validate_bashrc_file "$BASHRC_TEMP_FILE" "temporary Bash startup file for $BASHRC"; then
    echo "Error: refusing to replace $BASHRC because the generated file failed validation." >&2
    return 1
  fi

  if ! mv -- "$BASHRC_TEMP_FILE" "$BASHRC"; then
    echo "Error: failed to atomically replace $BASHRC; original file was left unchanged." >&2
    return 1
  fi

  BASHRC_TEMP_FILE=""
}

add_managed_link() {
  MANAGED_LINK_TARGETS+=("$1")
  MANAGED_LINK_DESTINATIONS+=("$2")
}

validate_managed_directory() {
  local path="$1"

  if [[ (-e "$path" || -L "$path") && ! -d "$path" ]]; then
    echo "Error: refusing to use non-directory path: $path" >&2
    return 1
  fi
}

validate_managed_link() {
  local target="$1"
  local destination="$2"
  local actual_target

  if [[ ! -f "$target" ]]; then
    echo "Error: missing managed target: $target" >&2
    return 1
  fi

  if [[ ! -e "$destination" && ! -L "$destination" ]]; then
    return 0
  fi

  if [[ -L "$destination" ]]; then
    actual_target="$(readlink "$destination")"

    if [[ "$actual_target" == "$target" ]]; then
      return 0
    fi

    echo "Error: refusing to replace unmanaged symlink: $destination -> $actual_target" >&2
    echo "Expected managed target: $target" >&2
    return 1
  fi

  echo "Error: refusing to replace unmanaged path: $destination" >&2
  echo "Expected managed target: $target" >&2
  return 1
}

create_managed_link() {
  local target="$1"
  local destination="$2"

  if [[ -L "$destination" && "$(readlink "$destination")" == "$target" ]]; then
    return 0
  fi

  if ! ln -sT -- "$target" "$destination"; then
    echo "Error: failed to create managed symlink: $destination" >&2
    echo "Existing paths were not removed; managed links created earlier in this run may remain." >&2
    return 1
  fi
}

add_managed_link "$DOTFILES_DIR/shell/aliases.sh" "$CONFIG_DIR/aliases.sh"
add_managed_link "$DOTFILES_DIR/shell/dotnet.sh" "$CONFIG_DIR/dotnet.sh"
add_managed_link "$DOTFILES_DIR/shell/git.sh" "$CONFIG_DIR/git.sh"
add_managed_link "$DOTFILES_DIR/git/config" "$CONFIG_DIR/gitconfig"

for script in "$DOTFILES_DIR"/bin/*; do
  [[ -f "$script" ]] || continue
  add_managed_link "$script" "$LOCAL_BIN/$(basename "$script")"
done

validate_managed_directory "$CONFIG_DIR"
validate_managed_directory "$LOCAL_BIN"

for index in "${!MANAGED_LINK_DESTINATIONS[@]}"; do
  validate_managed_link "${MANAGED_LINK_TARGETS[$index]}" "${MANAGED_LINK_DESTINATIONS[$index]}"
done

validate_bashrc_file "$BASHRC"

echo "Configuring development environment..."

mkdir -p "$CONFIG_DIR" "$LOCAL_BIN"

for index in "${!MANAGED_LINK_DESTINATIONS[@]}"; do
  create_managed_link "${MANAGED_LINK_TARGETS[$index]}" "${MANAGED_LINK_DESTINATIONS[$index]}"
done

ensure_managed_bashrc

LEGACY_GIT_CONFIG_FILE="$DOTFILES_DIR/git/config"
STABLE_GIT_CONFIG_FILE="$CONFIG_DIR/gitconfig"

# Migrate the original repository-relative include path, without touching unrelated includes.
git config --global --fixed-value --unset-all include.path "$LEGACY_GIT_CONFIG_FILE" 2>/dev/null || true

if ! git config --global --get-all include.path 2>/dev/null | grep -Fxq "$STABLE_GIT_CONFIG_FILE"; then
  git config --global --add include.path "$STABLE_GIT_CONFIG_FILE"
fi

if git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$DOTFILES_DIR" config --local core.hooksPath .githooks
fi

echo
echo "Development environment configured."
echo "Run 'source ~/.bashrc' or start a new shell."
