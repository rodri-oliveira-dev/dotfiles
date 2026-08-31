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
4. Treat filesystem paths, symlink targets, and user configuration files as sensitive mutation boundaries.
5. Make repeated execution safe.
6. Fail diagnostically instead of silently corrupting state.

# Review focus

Inspect changes for:

- word splitting and glob expansion;
- unbound variables;
- pipelines whose failures may be hidden;
- unsafe `rm`, `mv`, `cp`, or redirection targets;
- missing existence/type checks before filesystem operations;
- symlink replacement behavior;
- duplicate configuration blocks;
- PATH duplication;
- malformed heredocs;
- commands that depend on tools not guaranteed by the environment;
- ShellCheck warnings that indicate real correctness or maintainability issues.

# Process

1. Read `AGENTS.md` and the target scripts.
2. Define the existing observable behavior.
3. Identify the concrete shell-safety risk.
4. Apply the smallest correction.
5. Preserve idempotency.
6. Avoid broad rewrites purely for style.
7. Validate syntax and ShellCheck.
8. For installer changes, test repeated execution in an isolated environment when possible.

# Validation

```bash
bash -n install.sh
bash -n bin/*
bash -n shell/*.sh

shellcheck install.sh
shellcheck bin/*
shellcheck shell/*.sh
```

For `install.sh`, also verify that multiple runs do not duplicate the managed Bash block, Git includes, or PATH entries.

# Restrictions

- Do not suppress ShellCheck warnings globally just to obtain a green build.
- Do not add `eval` without a compelling and documented reason.
- Do not execute destructive filesystem operations against paths derived from unchecked input.
- Do not assume the current working directory unless the script explicitly requires it.
- Do not replace complete user-owned configuration files.
- Do not broaden permissions or use `sudo` without a concrete requirement.

# Quality criteria

A good hardening change reduces a specific failure mode, keeps the script understandable, remains idempotent, and passes syntax plus ShellCheck validation.
