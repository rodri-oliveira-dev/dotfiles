---
name: dotfiles-change
description: Use this skill for general changes to personal aliases, Git defaults, executable helpers, installation behavior, or repository-level configuration. Do not use it as the primary skill for deep Bash safety reviews or Codespaces-specific lifecycle changes.
license: MIT
---

# Objective

Guide small and safe changes to the dotfiles repository while preserving reproducibility, idempotency, and the boundary between personal environment preferences and project-specific requirements.

# When to use

- Changes under `shell/`.
- Changes under `bin/`.
- Changes to `git/config`.
- General changes to `install.sh` or `uninstall.sh`.
- Changes to `bin/dotfiles-doctor`.
- Changes to `.editorconfig`, `.gitattributes`, or `.gitignore`.
- Documentation updates that describe repository commands or behavior.
- Behavioral tests under `tests/`.
- Repository-level CI configuration when it directly supports dotfiles validation.

# When not to use

- Deep Bash safety or quoting analysis: use `shell-hardening`.
- GitHub Codespaces-specific behavior: use `codespaces-integration`.
- Project-specific .NET SDK, NuGet, test, or build changes: those belong in the target project repository.

# Process

1. Read `AGENTS.md` and the files directly related to the change.
2. Identify whether the change affects personal configuration, project configuration, or both.
3. Keep project-specific requirements outside this repository.
4. Apply the smallest coherent change.
5. Preserve backward compatibility of existing aliases and helpers unless a breaking change is explicitly requested.
6. Update both README language versions when user-facing behavior changes.
7. Review the diff for accidental environment coupling.
8. Run the relevant shell validation.

# Validation

For shell-related changes:

```bash
bash -n install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
shellcheck install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
shfmt -d -i 2 install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
bats tests
```

For documentation-only changes, verify links, paths, command names, and repository structure against the actual tree.

# Restrictions

- Do not install or pin a project-specific .NET SDK globally.
- Do not globally install tools that should come from a project's local tool manifest.
- Do not add secrets or credentials.
- Do not ignore `bin/`; it is source code here.
- Do not introduce MSBuild or NuGet infrastructure without an explicit repository requirement.
- Do not overwrite complete user configuration files for convenience.
- Uninstall logic must remove only exact repository-managed markers, Git includes, and symlinks; leave unrelated state untouched.
- CI changes must preserve minimal permissions, bounded runtime, action SHA pinning, and dependency-update automation unless there is a documented reason not to.

# Quality criteria

A good change has a focused diff, remains safe across repeated installation, preserves the separation between personal and project configuration, and keeps documentation synchronized with actual behavior.
