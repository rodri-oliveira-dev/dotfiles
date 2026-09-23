#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  WORKFLOW="$REPO_ROOT/.github/workflows/validate.yml"
}

@test "pull requests to main always report validation checks" {
  local pull_request_block

  pull_request_block="$(
    awk '
      $0 == "  pull_request:" {
        in_pull_request = 1
        next
      }

      in_pull_request && /^[^ ]/ {
        exit
      }

      in_pull_request {
        print
      }
    ' "$WORKFLOW"
  )"

  [[ "$pull_request_block" == *"    branches:"* ]]
  [[ "$pull_request_block" == *"      - main"* ]]
  [[ "$pull_request_block" != *"    paths:"* ]]
  [[ "$pull_request_block" != *"    paths-ignore:"* ]]
}

@test "required validation check names remain stable" {
  grep -Fxq "    name: Shell validation" "$WORKFLOW"
  grep -Fxq "    name: Clean container lifecycle" "$WORKFLOW"
}

@test "manual release runs only from current main and never reuses a tag" {
  local release_workflow="$REPO_ROOT/.github/workflows/release.yml"

  grep -Fxq "  workflow_dispatch:" "$release_workflow"
  grep -Fxq "  cancel-in-progress: false" "$release_workflow"
  grep -Fxq "permissions: {}" "$release_workflow"
  grep -Fxq "      contents: write" "$release_workflow"
  grep -Fq '[[ "$GITHUB_REF" != "refs/heads/main" ]]' "$release_workflow"
  grep -Fq '[[ "$GITHUB_SHA" != "$main_sha" ]]' "$release_workflow"
  grep -Fq 'gh api --method POST "repos/${GITHUB_REPOSITORY}/git/refs"' "$release_workflow"
  grep -Fq 'gh release create "$tag" --verify-tag' "$release_workflow"
  ! grep -Fq -- '--force' "$release_workflow"
}
