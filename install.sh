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

declare -a MANAGED_LINK_TARGETS=()
declare -a MANAGED_LINK_DESTINATIONS=()

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

  if ! ln -s -- "$target" "$destination"; then
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

echo "Configuring development environment..."

mkdir -p "$CONFIG_DIR" "$LOCAL_BIN"

for index in "${!MANAGED_LINK_DESTINATIONS[@]}"; do
  create_managed_link "${MANAGED_LINK_TARGETS[$index]}" "${MANAGED_LINK_DESTINATIONS[$index]}"
done

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
  git -C "$DOTFILES_DIR" config --local core.hooksPath .githooks
fi

echo
echo "Development environment configured."
echo "Run 'source ~/.bashrc' or start a new shell."
