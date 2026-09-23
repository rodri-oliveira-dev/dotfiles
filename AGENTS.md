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
- Installation must never overwrite, remove, or rename a pre-existing unmanaged destination; a managed symlink may be created only when the destination is absent or already points exactly to the expected target.
- Do not replace the user's complete `~/.bashrc` or `~/.gitconfig`.
- Treat `~/.bashrc` as an integrity boundary: refuse symlinks/non-regular files, require exact unique ordered managed markers, and stage rewrites beside the file before atomic replacement while preserving existing permissions.
- Preserve settings injected by GitHub Codespaces and other tools.
- Never run the installer or uninstaller as `root`; privileged execution is outside the supported lifecycle.
- Configure Git hooks locally for this repository; do not set a global `core.hooksPath` as part of dotfiles installation.
- Update helpers must refuse destructive reconciliation: do not reset, stash, or discard local changes automatically.
- Treat remote updates as a trust boundary: `dotfiles-update` must stay restricted to the documented `main`/`origin/main` distribution route, official repository URLs, validated fast-forward revisions, and hook-disabled fetch/merge operations before updated scripts execute.
- Quote shell variables unless unquoted expansion is deliberate and safe.
- Avoid destructive commands unless the target is tightly validated.
- Keep Docker test builds deny-by-default: do not use broad `COPY . .`; allow only required lifecycle inputs and keep local secrets, credentials, keys, logs, backups, caches, Git metadata, and temporary files outside image layers.
- Do not install project-specific SDKs, tools, databases, or services globally.
- Do not introduce secrets, tokens, private URLs, credentials, or private keys.
- Keep `bin/` versioned; it is source code in this repository, not build output.
- Keep documentation aligned with behavior whenever a command, helper, installation step, or supported convention changes.
- Do not weaken validation merely to make a change pass.
- Keep GitHub Actions permissions minimal and read-only unless a write capability is explicitly required.
- Pin third-party GitHub Actions to full commit SHAs; use Dependabot to maintain those pins.
- Keep security scanners fail-closed inside the stable `Shell validation` check. Scanner release binaries must use explicit versions plus verified SHA-256 digests; do not replace them with floating tags or unverified downloads.
- Gitleaks CI scanning covers the current committed snapshot with full redaction; full-history scanning is a deliberate manual audit. Never print or upload raw secret candidates merely to diagnose a finding.
- Keep zizmor offline in CI and do not grant scanner-specific tokens or write permissions. Treat scanner exceptions as narrow, documented policy decisions rather than blanket suppressions.
- Preserve push path filters, concurrency cancellation, and bounded job timeouts unless a concrete requirement justifies changing them; pull requests targeting `main` must not use path filters because the stable required checks must always be reported.

## Trust boundaries for repository-aware .NET commands

- Do not treat a checkout as trusted merely because it is a Git repository or because its files are readable.
- Before running project-aware .NET commands against external code, inspect repository-controlled inputs such as `global.json`, project files, `Directory.Build.props`, `Directory.Build.targets`, MSBuild imports, `Directory.Packages.props`, `.config/dotnet-tools.json`, and relevant `NuGet.config` files.
- Plain-text inspection is preferred for unknown repositories. `dotnet msbuild -getProperty/-getItem` performs MSBuild evaluation and is not a passive security sandbox.
- Treat `dotnet tool restore`, package restore, build, format, and test as operations requiring repository trust because they can access package feeds and/or load repository-controlled build/test tooling.
- Automated agents must not run MSBuild evaluation, tool/package restore, build, formatting, or tests on untrusted external code unless the task explicitly authorizes execution and the environment is appropriately constrained.
- For external code, prefer disposable environments without unrelated secrets and restrict network/filesystem permissions where practical. Never imply that these helpers isolate credentials, processes, the filesystem, or the network.

## Required validation

For shell-related changes, run from the repository root when the environment allows:

```bash
bash scripts/validate-shell
bash scripts/install-security-tools
bash scripts/security-scan
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
