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

@test "manual release requires main, checkout, explicit recovery and protected tag creation" {
  local release_workflow="$REPO_ROOT/.github/workflows/release.yml"

  grep -Fxq "  workflow_dispatch:" "$release_workflow"
  grep -Fxq "  cancel-in-progress: false" "$release_workflow"
  grep -Fxq "permissions: {}" "$release_workflow"
  grep -Fxq "      contents: write" "$release_workflow"
  grep -Fq '[[ "$GITHUB_REF" != "refs/heads/main" ]]' "$release_workflow"
  grep -Fq '[[ "$GITHUB_SHA" != "$main_sha" ]]' "$release_workflow"
  grep -Fxq "        default: false" "$release_workflow"
  grep -Fxq "        type: boolean" "$release_workflow"
  grep -Fxq "      RECOVER_EXISTING_TAG: ${{ inputs.recover_existing_tag }}" "$release_workflow"
  grep -Fq "uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1" "$release_workflow"
  grep -Fxq "          persist-credentials: false" "$release_workflow"
  grep -Fxq "          fetch-depth: 0" "$release_workflow"
  grep -Fq '[[ "$RECOVER_EXISTING_TAG" == "true" ]]' "$release_workflow"
  grep -Fq 'git merge-base --is-ancestor "$tag_sha" "$GITHUB_SHA"' "$release_workflow"
  grep -Fq 'gh release view "$tag" --repo "$GITHUB_REPOSITORY"' "$release_workflow"
  grep -Fq 'gh api --method POST "repos/${GITHUB_REPOSITORY}/git/refs"' "$release_workflow"
  grep -Fq 'gh release create "$tag" --repo "$GITHUB_REPOSITORY" --verify-tag' "$release_workflow"
  ! grep -Fq -- '--force' "$release_workflow"
}
