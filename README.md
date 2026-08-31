# dotfiles

Personal development environment configuration for **.NET**, **Git**, and **GitHub Codespaces**.

[English](README.md) | [Português (Brasil)](README.pt-BR.md)

This repository contains only developer-level preferences and helpers. Project-specific requirements remain inside each project repository.

## Goals

- Keep Git and shell preferences consistent across development environments.
- Provide small helpers for common .NET repository workflows.
- Work safely with GitHub Codespaces.
- Respect project-level configuration such as `global.json`, `Directory.Build.props`, `Directory.Packages.props`, and local .NET tool manifests.
- Avoid installing project dependencies globally.

## Responsibility boundaries

| Concern | Source of truth |
| --- | --- |
| Shell aliases and personal CLI helpers | This repository |
| Git defaults | This repository |
| .NET SDK version | Project `global.json` |
| NuGet package versions | Project files / `Directory.Packages.props` |
| MSBuild configuration | Project files / `Directory.Build.props` |
| Local .NET tools | Project `.config/dotnet-tools.json` |
| VS Code project extensions | Project `.vscode/extensions.json` |
| Personal VS Code preferences | VS Code Settings Sync |
| Secrets and credentials | GitHub Codespaces / repository / environment secrets |

## Repository structure

```text
dotfiles/
├── .agents/
│   └── skills/
│       ├── codespaces-integration/
│       │   └── SKILL.md
│       ├── dotfiles-change/
│       │   └── SKILL.md
│       └── shell-hardening/
│           └── SKILL.md
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       └── validate.yml
├── bin/
│   ├── dotfiles-doctor
│   ├── dotnet-bootstrap
│   ├── dotnet-context
│   └── git-root
├── git/
│   └── config
├── shell/
│   ├── aliases.sh
│   ├── dotnet.sh
│   └── git.sh
├── tests/
│   ├── dotnet-helpers.bats
│   ├── lifecycle.bats
│   └── test_helper.bash
├── .editorconfig
├── .gitattributes
├── .gitignore
├── AGENTS.md
├── AGENTS.pt-BR.md
├── install.sh
├── uninstall.sh
├── LICENSE
├── README.md
└── README.pt-BR.md
```

## Repository governance

This repository follows the same governance philosophy used by the .NET project template, but only applies conventions that make sense for a Bash/Git/Codespaces repository.

- `AGENTS.md` defines repository-wide rules for automated contributors.
- `.agents/skills/dotfiles-change/` covers general dotfiles changes.
- `.agents/skills/shell-hardening/` focuses on Bash safety and ShellCheck.
- `.agents/skills/codespaces-integration/` focuses on the GitHub Codespaces lifecycle and configuration boundaries.
- `Directory.Build.props` and `Directory.Packages.props` are intentionally absent because this repository does not contain an MSBuild project.

The governance files complement the actual repository configuration; they do not replace it as the source of truth.

## GitHub Codespaces

In GitHub:

1. Open **Settings**.
2. Go to **Codespaces**.
3. Find **Dotfiles**.
4. Enable automatic dotfiles installation.
5. Select this repository.

When a new Codespace is created, GitHub can clone this repository and execute `install.sh`.

The installer is designed to be idempotent. It:

- uses `${XDG_CONFIG_HOME:-$HOME/.config}/rodri-dotfiles` as the stable configuration location;
- links the shell helpers and Git configuration into that location;
- adds the dotfiles block to `~/.bashrc` only once and sources fragments only when readable;
- migrates the original repository-relative Git `include.path` to the stable configuration path;
- exposes scripts from `bin/` through `~/.local/bin`.

It deliberately does **not** replace the complete `~/.bashrc` or `~/.gitconfig`, which avoids overwriting configuration added by Codespaces or other tools.

## Supported environments

| Environment | Status | Notes |
| --- | --- | --- |
| GitHub Codespaces + Bash | Primary | Main target for automatic dotfiles installation |
| Linux + Bash | Supported | Same installation model as Codespaces |
| WSL + Bash | Expected | Designed to work, but not yet covered by dedicated CI |
| Zsh / PowerShell | Not configured | This repository currently manages Bash startup only |

## Lifecycle and diagnostics

Install or refresh the managed configuration:

```bash
./install.sh
source ~/.bashrc
```

Check the current environment:

```bash
dotfiles-doctor
```

The doctor validates the managed Bash block, PATH, configuration symlinks, Git `include.path`, executable helper links, Bash/Git availability, and reports the detected .NET SDK when available. It returns a non-zero exit code when a managed configuration invariant is broken.

Remove only configuration owned by this repository:

```bash
./uninstall.sh
```

The uninstaller removes the managed `~/.bashrc` block, exact Git include entries, and symlinks created by this repository. It deliberately leaves unrelated user files, Git settings, shell configuration, `~/.local/bin`, and non-managed files intact.

## .NET commands

### Aliases

| Alias | Command |
| --- | --- |
| `dr` | `dotnet restore` |
| `db` | `dotnet build` |
| `dt` | `dotnet test` |
| `dnfmt` | `dotnet format` |
| `dp` | `dotnet pack` |
| `dc` | `dotnet clean` |
| `dtr` | `dotnet tool restore` |
| `dtl` | `dotnet tool list` |
| `dsdks` | `dotnet --list-sdks` |
| `druntimes` | `dotnet --list-runtimes` |
| `dinfo` | `dotnet --info` |

### `dotnet-bootstrap`

Bootstraps a .NET repository from any directory inside the Git worktree.

If `.config/dotnet-tools.json` exists at the repository root, it restores local tools first. With exactly one root-level `.sln` or `.slnx`, that solution is restored automatically. If multiple solutions exist, the helper stops and requires an explicit target instead of choosing one arbitrarily.

```bash
dotnet-bootstrap
dotnet-bootstrap Ocelot.slnx
```

Additional restore options can be passed after the target. When there is only one solution, options may be passed directly.

### `dotnet-context`

Displays the effective SDK and detects common repository conventions from the Git repository root, even when invoked from a nested directory:

- `global.json`;
- `Directory.Build.props`;
- `Directory.Packages.props`;
- local .NET tool manifests;
- `.sln` and `.slnx` files.

```bash
dotnet-context
```

### `dotnet-sdk`

Shows the repository SDK configuration and the SDK resolved by the .NET CLI.

```bash
dotnet-sdk
```

### `dotnet-tools`

Lists project-local .NET tools when the repository contains a tool manifest.

```bash
dotnet-tools
```

### `dotnet-solutions`

Lists `.sln` and `.slnx` files from the Git repository root without selecting one automatically.

```bash
dotnet-solutions
```

## Git commands

### Aliases

| Alias | Command |
| --- | --- |
| `gs` | `git status --short --branch` |
| `gb` | `git branch` |
| `gba` | `git branch --all` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gl` | `git log --graph --decorate --oneline --all` |

### Helpers

`git-root` prints the current repository root.

```bash
git-root
```

`git-default-branch` resolves the remote default branch and falls back to `main` or `master`.

```bash
git-default-branch
```

`git-recent-branches` lists recently updated local branches.

```bash
git-recent-branches
git-recent-branches 20
```

## Design decisions

### Project SDKs stay project-scoped

This repository does not install or pin a .NET SDK globally.

A repository that requires a specific SDK should define it in `global.json`. This allows different projects to use different .NET 10 feature bands without coupling them to the personal environment.

### .NET tools stay project-scoped

Tools such as SonarScanner should remain in `.config/dotnet-tools.json` when they are part of the project toolchain.

Use:

```bash
dotnet tool restore
```

or:

```bash
dotnet-bootstrap
```

instead of installing those tools globally.

### VS Code extensions stay project-scoped

Project-specific extension recommendations belong in `.vscode/extensions.json`.

Personal editor preferences should be synchronized through VS Code Settings Sync rather than installed by `install.sh`.

## Validation and automated tests

The repository validates both static quality and observable behavior.

Static validation:

- Bash syntax with `bash -n`;
- shell analysis with ShellCheck;
- deterministic shell formatting with `shfmt -d -i 2`.

Behavioral validation uses Bats and covers installation idempotency, stable configuration links, Git include management, doctor/uninstall behavior, repository-root discovery, local .NET tool restore, and single/multiple solution handling.

Run locally after installing `bats` and `shfmt`:

```bash
bash -n install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
shellcheck install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
shfmt -d -i 2 install.sh uninstall.sh bin/* shell/*.sh tests/test_helper.bash
bats tests
```

Bats and shfmt are development/CI dependencies only; `install.sh` does not install them into the personal environment.

### CI hardening

The validation workflow is intentionally scoped and hardened:

- it runs only when shell/runtime validation inputs change, avoiding runner usage for documentation-only changes;
- concurrency cancels older runs for the same ref when a newer commit arrives;
- the validation job has a five-minute timeout;
- repository permissions are read-only;
- `actions/checkout` is pinned to a full commit SHA and does not persist credentials;
- Dependabot checks GitHub Actions dependencies weekly and groups available action updates into a single pull request.

Files:

```text
.github/workflows/validate.yml
.github/dependabot.yml
```

If this workflow is later configured as a required status check, review the path filters before relying on it for documentation-only pull requests.

## Security

Never commit:

- Personal Access Tokens;
- NuGet API keys;
- passwords;
- connection strings;
- cloud credentials;
- SSH private keys;
- other secrets.

Use GitHub Codespaces secrets, repository secrets, or environment secrets instead.

## License

MIT. See [LICENSE](LICENSE).
