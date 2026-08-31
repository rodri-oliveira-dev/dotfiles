#!/usr/bin/env bash

_dotnet_repository_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

dotnet-sdk() {
  local root
  local sdk

  root="$(_dotnet_repository_root)"

  if [[ -f "$root/global.json" ]]; then
    echo "Repository SDK configuration:"
    cat "$root/global.json"
    echo
  else
    echo "global.json: not found"
    echo
  fi

  if ! command -v dotnet >/dev/null 2>&1; then
    echo ".NET SDK not found"
    return 1
  fi

  if ! sdk="$(cd "$root" && dotnet --version)"; then
    echo "Unable to resolve a compatible .NET SDK for this repository." >&2
    return 1
  fi

  echo "Resolved SDK:"
  printf '%s\n' "$sdk"
}

dotnet-tools() {
  local root

  root="$(_dotnet_repository_root)"

  if [[ ! -f "$root/.config/dotnet-tools.json" ]]; then
    echo "No local .NET tool manifest found."
    return 0
  fi

  (cd "$root" && dotnet tool list)
}

dotnet-solutions() {
  local root
  local solutions

  root="$(_dotnet_repository_root)"

  shopt -s nullglob
  solutions=("$root"/*.sln "$root"/*.slnx)
  shopt -u nullglob

  if (("${#solutions[@]}" == 0)); then
    echo "No solution files found in repository root."
    return 0
  fi

  local solution
  for solution in "${solutions[@]}"; do
    printf '%s\n' "${solution#"$root"/}"
  done
}
