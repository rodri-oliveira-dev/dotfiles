# AGENTS.md

[English](AGENTS.md) | [Português (Brasil)](AGENTS.pt-BR.md)

## Purpose

This repository contains personal development-environment configuration for Git, Bash, .NET workflows, and GitHub Codespaces.

Changes must stay small, reproducible, safe to rerun, and aligned with the repository's actual behavior. Do not treat conventions from the .NET library template as requirements unless they are relevant to this repository.

## Sources of truth

Read only what is relevant to the task, prioritizing:

1. `README.md` and `README.pt-BR.md`;
2. `install.sh` and `uninstall.sh`;
3. files under `shell/`;
4. files under `bin/`;
5. repository hooks under `.githooks/` and shared validation under `scripts/`;
6. `git/config`;
7. `.editorconfig`, `.gitattributes`, `.gitignore`, `.dockerignore`, and `Dockerfile.test`;
8. tests under `tests/`;
9. workflows that actually exist under `.github/workflows/`;
10. `.github/dependabot.yml` for automated GitHub Actions dependency maintenance;
11. `.agents/skills/` for specialized tasks.

Do not assume a tool, workflow, service, secret, or dependency exists unless it is present in the repository or explicitly provided by the environment.

## Repository boundaries

- Personal shell preferences and aliases belong in `shell/`.
- Small executable helpers belong in `bin/`.
- Repository-local Git hooks belong in `.githooks/`; they must not override hooks in unrelated repositories.
- Shared repository validation entry points belong in `scripts/`.
- Personal Git defaults belong in `git/config`.
- Installation and linking behavior belongs in `install.sh`; safe removal belongs in `uninstall.sh`; environment diagnostics belong in `bin/dotfiles-doctor`.
- Project-specific .NET SDK versions belong in each project's `global.json`.
- Project-specific .NET tools belong in each project's `.config/dotnet-tools.json`.
- Project-specific editor extensions belong in each project's `.vscode/extensions.json`.
- Secrets never belong in this repository.

Do not add `Directory.Build.props`, `Directory.Packages.props`, project files, or NuGet dependencies unless this repository itself gains an explicit MSBuild-based component.

## Change rules

- Prefer the smallest change that solves the problem.
- Preserve idempotency: running `install.sh` repeatedly must not duplicate configuration or corrupt the environment.
- Preserve reversibility: `uninstall.sh` must remove only repository-managed state and leave unrelated user configuration intact.
- Do not replace the user's complete `~/.bashrc` or `~/.gitconfig`.
- Preserve settings injected by GitHub Codespaces and other tools.
- Never run the installer or uninstaller as `root`; privileged execution is outside the supported lifecycle.
- Configure Git hooks locally for this repository; do not set a global `core.hooksPath` as part of dotfiles installation.
- Update helpers must refuse destructive reconciliation: do not reset, stash, or discard local changes automatically.
- Quote shell variables unless unquoted expansion is deliberate and safe.
- Avoid destructive commands unless the target is tightly validated.
- Do not install project-specific SDKs, tools, databases, or services globally.
- Do not introduce secrets, tokens, private URLs, credentials, or private keys.
- Keep `bin/` versioned; it is source code in this repository, not build output.
- Keep documentation aligned with behavior whenever a command, helper, installation step, or supported convention changes.
- Do not weaken validation merely to make a change pass.
- Keep GitHub Actions permissions minimal and read-only unless a write capability is explicitly required.
- Pin third-party GitHub Actions to full commit SHAs; use Dependabot to maintain those pins.
- Preserve path filters, concurrency cancellation, and bounded job timeouts unless a concrete requirement justifies changing them.

## Required validation

For shell-related changes, run from the repository root when the environment allows:

```bash
bash scripts/validate-shell
bats tests
docker build --file Dockerfile.test --tag dotfiles-lifecycle-test .
```

`bash scripts/validate-shell` is the shared static-validation entry point used by local repository hooks and CI. The pre-commit hook may use `--allow-missing-tools` so Bash syntax still runs when ShellCheck or shfmt are absent locally; CI must enforce all tools without that option.

Bats tests are the executable baseline for lifecycle, update, and .NET helper behavior. For changes to `install.sh`, keep the idempotency coverage proving that:

- the managed block is not duplicated in `~/.bashrc`;
- Git `include.path` is not duplicated;
- repository-local `core.hooksPath` points to `.githooks`;
- symlinks remain valid;
- `~/.local/bin` is not duplicated in `PATH`.

The clean-container test must continue to prove that root installation is rejected and that install, doctor, repeated install, and uninstall work for a normal Linux user.

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
