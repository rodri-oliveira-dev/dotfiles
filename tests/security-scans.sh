#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$(mktemp -d)"
OUTPUT_FILE="$(mktemp)"
SYNTHETIC_SECRET="DOTFILES_SYNTHETIC_SECRET_ABCDEFGHIJKLMNOPQRSTUVWX"

cleanup() {
  rm -rf -- "$FIXTURE_DIR"
  rm -f -- "$OUTPUT_FILE"
}
trap cleanup EXIT

command -v gitleaks >/dev/null 2>&1 || {
  echo "Error: gitleaks is required for the synthetic security test." >&2
  exit 1
}

printf 'fixture = "%s"\n' "$SYNTHETIC_SECRET" >"$FIXTURE_DIR/fixture.txt"

if gitleaks dir   --config "$ROOT_DIR/.gitleaks.toml"   --no-banner   --no-color   --redact=100   --exit-code 1   "$FIXTURE_DIR" >"$OUTPUT_FILE" 2>&1; then
  echo "Error: Gitleaks did not block the synthetic secret fixture." >&2
  exit 1
fi

if grep -Fq "$SYNTHETIC_SECRET" "$OUTPUT_FILE"; then
  echo "Error: Gitleaks output exposed the synthetic secret instead of redacting it." >&2
  exit 1
fi

printf 'Synthetic secret gate test completed successfully.\n'
