#!/usr/bin/env bash

git-default-branch() {
  local branch

  branch="$(git remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p')"

  if [[ -n "${branch}" ]]; then
    printf '%s\n' "${branch}"
    return 0
  fi

  if git show-ref --verify --quiet refs/heads/main; then
    printf 'main\n'
    return 0
  fi

  if git show-ref --verify --quiet refs/heads/master; then
    printf 'master\n'
    return 0
  fi

  return 1
}

git-recent-branches() {
  git for-each-ref \
    --sort=-committerdate \
    --format='%(committerdate:short) %(refname:short)' \
    refs/heads/ |
    head -n "${1:-10}"
}
