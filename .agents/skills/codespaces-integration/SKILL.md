---
name: codespaces-integration
description: Use this skill for GitHub Codespaces dotfiles installation, user-environment initialization, PATH integration, Git configuration boundaries, shell startup behavior, and secret handling. Do not use it for project-specific devcontainer configuration unless the task explicitly connects that behavior to these dotfiles.
license: MIT
---

# Objective

Keep this repository safe and predictable when GitHub Codespaces clones and applies it to a new development environment.

# Core boundary

These dotfiles configure the developer environment. They must not become the source of truth for a project's SDK, packages, services, ports, databases, or application runtime requirements.

Project requirements belong in files such as:

- `global.json`;
- `.config/dotnet-tools.json`;
- `.devcontainer/devcontainer.json`;
- `Directory.Build.props`;
- `Directory.Packages.props`;
- project-local `.vscode/` configuration.

# When to use

- Changes to automatic dotfiles installation.
- Changes to `install.sh` that affect Codespaces startup.
- Changes to `uninstall.sh` or `dotfiles-doctor` that affect the managed Codespaces lifecycle.
- PATH initialization.
- Bash startup-file integration.
- Git configuration integration in Codespaces.
- Guidance about Codespaces secrets.
- Decisions about what belongs in dotfiles versus a project's devcontainer.

# Process

1. Read `AGENTS.md`, `install.sh`, and the relevant documentation.
2. Identify what GitHub Codespaces may already configure.
3. Preserve existing user and platform configuration instead of replacing it wholesale.
4. Keep installation idempotent.
5. Prefer linking repository-managed fragments over copying or replacing entire user files.
6. Keep credentials out of version control.
7. Keep project-specific tooling out of the global environment.
8. Update English and Portuguese documentation when the setup flow changes.
9. Validate shell behavior and repeated execution.

# Security rules

- Never version Personal Access Tokens, API keys, cloud credentials, SSH private keys, passwords, or connection strings.
- Do not persist secrets into shell profiles from repository content.
- Use GitHub Codespaces secrets or repository/environment secrets for credentials.
- Do not disable platform-provided Git signing or identity configuration without an explicit requirement.
- Do not grant broader repository access from scripts.

# Idempotency expectations

Repeated installation must not:

- duplicate the managed block in `~/.bashrc`;
- duplicate `git config --global include.path`;
- duplicate `~/.local/bin` in PATH;
- create conflicting copies of managed helper scripts;
- overwrite unrelated Git or shell configuration.

Uninstallation must remove only state that can be proven to be managed by this repository and must leave unrelated user configuration unchanged.

# Validation

Run:

```bash
bash -n install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
shellcheck install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
shfmt -d -i 2 install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
bats tests
```

Lifecycle behavior must be covered with a disposable HOME in Bats, including repeated installation, doctor validation, Git include management, and conservative uninstall behavior.

# Restrictions

- Do not install a fixed .NET SDK globally from this repository.
- Do not install project-local .NET tools globally.
- Do not add databases, Docker Compose services, or application ports here.
- Do not overwrite complete `~/.bashrc` or `~/.gitconfig`.
- Do not treat VS Code project-extension recommendations as a dotfiles responsibility.

# Quality criteria

A good Codespaces change starts cleanly, remains safe when rerun, preserves platform-managed configuration, exposes only developer-level helpers, and keeps project-specific requirements in the project repository.
