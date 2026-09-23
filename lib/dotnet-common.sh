#!/usr/bin/env bash

# Shared, source-only primitives for bin/dotnet-* helpers. This file is not a
# public command and intentionally does not change shell options or print on
# success. Callers retain their CLI parsing, output, and exit-code contracts.

dotnet_common_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

dotnet_common_require_host() {
  local failure_code="${1:-2}"

  if ! command -v dotnet >/dev/null 2>&1; then
    echo "Error: .NET SDK is not available in PATH." >&2
    return "$failure_code"
  fi
}

dotnet_common_resolve_sdk() {
  local root="$1"
  local without_global_message="$2"

  if ! SDK_VERSION="$(cd "$root" && dotnet --version 2>/dev/null)"; then
    if [[ -f "$root/global.json" ]]; then
      echo "Error: no compatible .NET SDK could be resolved for $root/global.json." >&2
    else
      printf 'Error: %s\n' "$without_global_message" >&2
    fi
    return 2
  fi
}

dotnet_common_parse_sdk_triplet() {
  local sdk_core="${SDK_VERSION%%-*}"

  IFS=. read -r SDK_MAJOR SDK_MINOR SDK_PATCH _ <<<"$sdk_core"

  if ! [[ "$SDK_MAJOR" =~ ^[0-9]+$ && "$SDK_MINOR" =~ ^[0-9]+$ && "$SDK_PATCH" =~ ^[0-9]+$ ]]; then
    printf 'Error: unable to interpret resolved .NET SDK version: %s\n' "$SDK_VERSION" >&2
    return 2
  fi
}

dotnet_common_require_msbuild_sdk() {
  local sdk_core="${SDK_VERSION%%-*}"

  IFS=. read -r SDK_MAJOR _ <<<"$sdk_core"

  if ! [[ "$SDK_MAJOR" =~ ^[0-9]+$ ]] || ((SDK_MAJOR < 8)); then
    printf 'Error: MSBuild evaluation helpers require .NET SDK 8 or later; resolved %s.\n' "$SDK_VERSION" >&2
    return 2
  fi
}

dotnet_common_find_solutions() {
  local root="$1"

  shopt -s nullglob
  SOLUTIONS=("$root"/*.sln "$root"/*.slnx)
  shopt -u nullglob
}

dotnet_common_find_projects() {
  local root="$1"

  mapfile -t PROJECTS < <(
    find "$root" \
      \( -type d \( \
      -name .git -o \
      -name bin -o \
      -name obj -o \
      -name node_modules -o \
      -name artifacts -o \
      -name .artifacts \
      \) -prune \) -o \
      \( -type f \( \
      -name '*.csproj' -o \
      -name '*.fsproj' -o \
      -name '*.vbproj' \
      \) -print \) | sort
  )
}

dotnet_common_print_solution_choices() {
  local root="$1"
  local example="$2"
  local solution

  echo "Multiple solution files were found in the repository root:" >&2

  for solution in "${SOLUTIONS[@]}"; do
    printf '  - %s\n' "${solution#"$root"/}" >&2
  done

  echo >&2
  echo "Specify the target explicitly, for example:" >&2
  printf '  %s %s\n' "$example" "${SOLUTIONS[0]#"$root"/}" >&2
}

dotnet_common_print_project_choices() {
  local root="$1"
  local example="$2"
  local heading="$3"
  local project

  printf '%s\n' "$heading" >&2

  for project in "${PROJECTS[@]}"; do
    printf '  - %s\n' "${project#"$root"/}" >&2
  done

  echo >&2
  echo "Specify the target explicitly, for example:" >&2
  printf '  %s %s\n' "$example" "${PROJECTS[0]#"$root"/}" >&2
}

dotnet_common_resolve_explicit_target() {
  local root="$1"
  local explicit="$2"
  local kind="${3:-any}"

  if [[ "$explicit" == /* ]]; then
    TARGET="$explicit"
  else
    TARGET="$root/$explicit"
  fi

  if [[ "$kind" == "project" ]]; then
    if [[ ! -f "$TARGET" ]]; then
      printf 'Error: target does not exist: %s\n' "$explicit" >&2
      return 2
    fi

    case "$TARGET" in
    *.csproj | *.fsproj | *.vbproj) ;;
    *)
      printf 'Error: target must be a .csproj, .fsproj, or .vbproj file: %s\n' "$explicit" >&2
      return 2
      ;;
    esac
  elif [[ ! -e "$TARGET" ]]; then
    printf 'Error: target does not exist: %s\n' "$explicit" >&2
    return 2
  fi
}

dotnet_common_select_solution_target() {
  local root="$1"
  local explicit="$2"
  local example="$3"

  TARGET=""
  if [[ -n "$explicit" ]]; then
    dotnet_common_resolve_explicit_target "$root" "$explicit"
    return $?
  fi

  case "${#SOLUTIONS[@]}" in
  0) ;;
  1) TARGET="${SOLUTIONS[0]}" ;;
  *)
    dotnet_common_print_solution_choices "$root" "$example"
    return 2
    ;;
  esac
}

dotnet_common_select_project_target() {
  local root="$1"
  local explicit="$2"
  local example="$3"

  TARGET=""
  if [[ -n "$explicit" ]]; then
    dotnet_common_resolve_explicit_target "$root" "$explicit" project
    return $?
  fi

  case "${#PROJECTS[@]}" in
  0)
    echo "Error: no .NET project files were found in the repository." >&2
    return 2
    ;;
  1) TARGET="${PROJECTS[0]}" ;;
  *)
    dotnet_common_print_project_choices "$root" "$example" "Multiple project files were found in the repository:"
    return 2
    ;;
  esac
}
