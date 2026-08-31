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
├── .github/
│   └── workflows/
│       └── validate.yml
├── bin/
│   ├── dotnet-bootstrap
│   ├── dotnet-context
│   └── git-root
├── git/
│   └── config
├── shell/
│   ├── aliases.sh
│   ├── dotnet.sh
│   └── git.sh
├── .editorconfig
├── .gitattributes
├── .gitignore
├── install.sh
├── LICENSE
├── README.md
└── README.pt-BR.md
```

## GitHub Codespaces

In GitHub:

1. Open **Settings**.
2. Go to **Codespaces**.
3. Find **Dotfiles**.
4. Enable automatic dotfiles installation.
5. Select this repository.

When a new Codespace is created, GitHub can clone this repository and execute `install.sh`.

The installer is designed to be idempotent. It:

- creates the required local configuration directories;
- links the shell helper files;
- adds the dotfiles block to `~/.bashrc` only once;
- adds this repository's Git configuration through `include.path`;
- exposes scripts from `bin/` through `~/.local/bin`.

It deliberately does **not** replace the complete `~/.bashrc` or `~/.gitconfig`, which avoids overwriting configuration added by Codespaces or other tools.

## Manual installation

Clone the repository and run:

```bash
./install.sh
source ~/.bashrc
```

## .NET commands

### Aliases

| Alias | Command |
| --- | --- |
| `dr` | `dotnet restore` |
| `db` | `dotnet build` |
| `dt` | `dotnet test` |
| `df` | `dotnet format` |
| `dp` | `dotnet pack` |
| `dc` | `dotnet clean` |
| `dtr` | `dotnet tool restore` |
| `dtl` | `dotnet tool list` |
| `dsdks` | `dotnet --list-sdks` |
| `druntimes` | `dotnet --list-runtimes` |
| `dinfo` | `dotnet --info` |

### `dotnet-bootstrap`

Bootstraps a .NET repository.

If `.config/dotnet-tools.json` exists, it restores local tools first and then restores NuGet packages.

```bash
dotnet-bootstrap
```

Additional arguments are forwarded to `dotnet restore`.

### `dotnet-context`

Displays the effective SDK and detects common repository conventions:

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

Lists `.sln` and `.slnx` files in the repository root without selecting one automatically.

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

## Validation

The repository includes a GitHub Actions workflow that validates:

- Bash syntax with `bash -n`;
- shell scripts with ShellCheck.

Workflow:

```text
.github/workflows/validate.yml
```

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
