---
name: shell-hardening
description: Use this skill to review or modify Bash scripts with emphasis on quoting, error handling, path safety, symlinks, idempotency, destructive operations, and ShellCheck compliance. Do not use it for documentation-only changes.
license: MIT
---

# Objective

Improve shell-script reliability and safety without introducing unnecessary complexity or changing behavior outside the requested scope.

# Principles

1. Prefer explicit, readable Bash.
2. Preserve `set -euo pipefail` where appropriate.
3. Quote variable expansions unless unquoted expansion is intentionally required.
4. Treat filesystem paths, symlink targets, Git configuration, and user configuration files as sensitive mutation boundaries.
5. Make repeated execution safe.
6. Fail diagnostically instead of silently corrupting state.
7. Never discard local Git work automatically from lifecycle helpers.

# Review focus

Inspect changes for:

- word splitting and glob expansion;
- unbound variables;
- pipelines whose failures may be hidden;
- unsafe `rm`, `mv`, `cp`, reset, stash, or redirection targets;
- missing existence/type checks before filesystem operations;
- symlink replacement behavior;
- duplicate configuration blocks;
- PATH duplication;
- malformed heredocs;
- commands that depend on tools not guaranteed by the environment;
- accidental global Git configuration when repository-local configuration is sufficient;
- privileged/root execution outside explicitly supported paths;
- formatting drift detectable by `shfmt`;
- ShellCheck warnings that indicate real correctness or maintainability issues.

# Process

1. Read `AGENTS.md` and the target scripts.
2. Define the existing observable behavior.
3. Identify the concrete shell-safety risk.
4. Apply the smallest correction.
5. Preserve idempotency and reversibility.
6. Avoid broad rewrites purely for style.
7. Validate through the shared shell validator and Bats.
8. For lifecycle changes, test repeated execution in the clean container when possible.

# Validation

```bash
bash scripts/validate-shell
bats tests
docker build --file Dockerfile.test --tag dotfiles-lifecycle-test .
```

Bats tests must continue to prove that multiple installations do not duplicate the managed Bash block, Git includes, repository hook configuration, or PATH entries, and that uninstall preserves unrelated state.

The clean-container test must continue to prove that `install.sh` refuses root execution and that the supported non-root lifecycle succeeds.

# Restrictions

- Do not suppress ShellCheck warnings globally just to obtain a green build.
- Do not add `eval` without a compelling and documented reason.
- Do not execute destructive filesystem operations against paths derived from unchecked input.
- Do not assume the current working directory unless the script explicitly requires it.
- Do not replace complete user-owned configuration files.
- Do not broaden permissions or use `sudo` without a concrete requirement.
- Do not configure a global `core.hooksPath` when a repository-local hooks path satisfies the requirement.
- Do not make update helpers reset, stash, or discard uncommitted work automatically.

# CI expectations

When shell validation changes, preserve:

- `scripts/validate-shell` as the shared static-validation gate;
- ShellCheck and shfmt enforcement in CI;
- Bats as the behavioral gate;
- a clean-container lifecycle gate for environment-level behavior;
- bounded workflow timeouts;
- cancellation of stale runs for the same ref;
- full-SHA pinning for third-party actions.

# Quality criteria

A good hardening change reduces a specific failure mode, keeps the script understandable, remains idempotent and reversible, and passes static, behavioral, and environment-level validation.
