# AGENTS.md

[English](AGENTS.md) | [Português (Brasil)](AGENTS.pt-BR.md)

## Purpose

This repository contains personal development-environment configuration for Git, Bash, .NET workflows, and GitHub Codespaces.

Changes must stay small, reproducible, safe to rerun, and aligned with the repository's actual behavior. Do not treat conventions from the .NET library template as requirements unless they are relevant to this repository.

## Sources of truth

Read only what is relevant to the task, prioritizing:

1. `README.md` and `README.pt-BR.md`;
2. `install.sh`;
3. files under `shell/`;
4. files under `bin/`;
5. `git/config`;
6. `.editorconfig`, `.gitattributes`, and `.gitignore`;
7. workflows that actually exist under `.github/workflows/`;
8. `.agents/skills/` for specialized tasks.

Do not assume a tool, workflow, service, secret, or dependency exists unless it is present in the repository or explicitly provided by the environment.

## Repository boundaries

- Personal shell preferences and aliases belong in `shell/`.
- Small executable helpers belong in `bin/`.
- Personal Git defaults belong in `git/config`.
- Installation and linking behavior belongs in `install.sh`.
- Project-specific .NET SDK versions belong in each project's `global.json`.
- Project-specific .NET tools belong in each project's `.config/dotnet-tools.json`.
- Project-specific editor extensions belong in each project's `.vscode/extensions.json`.
- Secrets never belong in this repository.

Do not add `Directory.Build.props`, `Directory.Packages.props`, project files, or NuGet dependencies unless this repository itself gains an explicit MSBuild-based component.

## Change rules

- Prefer the smallest change that solves the problem.
- Preserve idempotency: running `install.sh` repeatedly must not duplicate configuration or corrupt the environment.
- Do not replace the user's complete `~/.bashrc` or `~/.gitconfig`.
- Preserve settings injected by GitHub Codespaces and other tools.
- Quote shell variables unless unquoted expansion is deliberate and safe.
- Avoid destructive commands unless the target is tightly validated.
- Do not install project-specific SDKs, tools, databases, or services globally.
- Do not introduce secrets, tokens, private URLs, credentials, or private keys.
- Keep `bin/` versioned; it is source code in this repository, not build output.
- Keep documentation aligned with behavior whenever a command, helper, installation step, or supported convention changes.
- Do not weaken validation merely to make a change pass.

## Required validation

For changes to shell scripts, run from the repository root when the environment allows:

```bash
bash -n install.sh
bash -n bin/*
bash -n shell/*.sh

shellcheck install.sh
shellcheck bin/*
shellcheck shell/*.sh
```

For changes to `install.sh`, also verify idempotency in an isolated or disposable environment when possible by executing it more than once and confirming that:

- the managed block is not duplicated in `~/.bashrc`;
- Git `include.path` is not duplicated;
- symlinks remain valid;
- `~/.local/bin` is not duplicated in `PATH`.

If a validation cannot be executed because of a real environment limitation, report the limitation rather than weakening the baseline.

## Skills

Use a skill only when its description matches the task:

- `.agents/skills/dotfiles-change/SKILL.md`: general repository changes involving aliases, helpers, Git defaults, or installation behavior;
- `.agents/skills/shell-hardening/SKILL.md`: Bash safety, quoting, error handling, symlinks, paths, and ShellCheck;
- `.agents/skills/codespaces-integration/SKILL.md`: GitHub Codespaces lifecycle, dotfiles installation, user configuration, PATH, Git identity boundaries, and secrets.

The skills complement this file. If they conflict, `AGENTS.md` and the repository's real files take precedence.

## Git and delivery

- Review the diff before concluding.
- Avoid unrelated formatting or refactoring.
- Do not add generated artifacts or temporary files.
- Do not push, create releases, or change repository administration unless explicitly requested.
- When finishing a change, report the validations executed and any remaining risk or blocker.
