#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$(mktemp -d)"
REPO_DIR="$(mktemp -d)"
OUTPUT_FILE="$(mktemp)"
SYNTHETIC_SECRET="DOTFILES_SYNTHETIC_SECRET_$(printf '%s%s' 'ABCDEFGHIJKL' 'MNOPQRSTUVWX')"

cleanup() {
  rm -rf -- "$FIXTURE_DIR" "$REPO_DIR"
  rm -f -- "$OUTPUT_FILE"
}
trap cleanup EXIT

for tool in gitleaks git tar; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Error: %s is required for the synthetic security test.\n' "$tool" >&2
    exit 1
  fi
done

assert_detected_and_redacted() {
  local status="$1"
  local expected_finding="$2"

  if ((status != 1)); then
    printf 'Error: expected a Gitleaks finding (exit 1); scanner returned %s.\n' "$status" >&2
    exit 1
  fi

  if ! grep -Fq "$expected_finding" "$OUTPUT_FILE"; then
    echo "Error: expected finding evidence is missing from Gitleaks output." >&2
    exit 1
  fi

  if grep -Fq "$SYNTHETIC_SECRET" "$OUTPUT_FILE"; then
    echo "Error: Gitleaks output exposed the synthetic secret instead of redacting it." >&2
    exit 1
  fi
}

printf 'fixture = "%s"\n' "$SYNTHETIC_SECRET" >"$FIXTURE_DIR/fixture.txt"

status=0
gitleaks dir --verbose --config "$ROOT_DIR/.gitleaks.toml" --no-banner --no-color --redact=100 --exit-code 1 "$FIXTURE_DIR" >"$OUTPUT_FILE" 2>&1 || status=$?
assert_detected_and_redacted "$status" "dotfiles-synthetic-secret"

# The tracked fixture is deliberately omitted by git archive. The production
# scan must still find it through the committed blob, without using worktree
# files, credentials or any real secret.
git -C "$REPO_DIR" init -q -b main
printf 'fixture.txt export-ignore\n' >"$REPO_DIR/.gitattributes"
printf 'fixture = "%s"\n' "$SYNTHETIC_SECRET" >"$REPO_DIR/fixture.txt"
git -C "$REPO_DIR" add -- .gitattributes fixture.txt
git -C "$REPO_DIR" -c user.name="Security Fixture" -c user.email="fixture@example.invalid" commit -qm "synthetic export-ignore fixture"

if git -C "$REPO_DIR" archive HEAD | tar -tf - | grep -Fxq 'fixture.txt'; then
  echo "Error: synthetic fixture was not excluded from git archive." >&2
  exit 1
fi

: >"$OUTPUT_FILE"
status=0
bash "$ROOT_DIR/scripts/scan-tracked-secrets" "$REPO_DIR" >"$OUTPUT_FILE" 2>&1 || status=$?
assert_detected_and_redacted "$status" "leaks found"

printf 'Synthetic secret and export-ignore regression tests completed successfully.\n'
