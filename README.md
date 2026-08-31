# dotfiles

Personal development environment configuration focused on .NET development and GitHub Codespaces.

The repository intentionally keeps personal environment preferences separate from project requirements:

- **dotfiles**: shell aliases, Git defaults, and personal CLI helpers.
- **repository**: .NET SDK version, local tools, package management, services, ports, and build configuration.
- **VS Code Settings Sync / `.vscode`**: editor preferences and project-specific extension recommendations.

## Principles

- Do not install a global .NET SDK from this repository.
- Do not install project-scoped .NET tools globally.
- Respect each repository's `global.json`.
- Respect `.config/dotnet-tools.json` and use `dotnet tool restore`.
- Do not store secrets, tokens, API keys, SSH private keys, or connection strings.
- Keep installation idempotent and safe for GitHub Codespaces.

## Installation

GitHub Codespaces can automatically clone this repository and run `install.sh`.

For a manual installation:

```bash
./install.sh
source ~/.bashrc
```

## Commands

### .NET aliases

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
| `dinfo` | `dotnet --info` |

### Helpers

`dotnet-bootstrap`

Restores project-local .NET tools when a manifest exists, then restores NuGet packages.

```bash
dotnet-bootstrap
```

`dotnet-context`

Shows the active SDK and detects common repository conventions such as `global.json`,
`Directory.Build.props`, `Directory.Packages.props`, local tool manifests, `.sln`, and `.slnx`.

```bash
dotnet-context
```

`dotnet-sdk`

Shows the repository SDK configuration and the SDK resolved by the .NET CLI.

```bash
dotnet-sdk
```

`dotnet-solutions`

Lists solution files in the repository root without selecting one automatically.

```bash
dotnet-solutions
```

`git-root`

Prints the current Git repository root.

```bash
git-root
```

## Why project tools are not installed globally

The .NET repositories this environment targets commonly use `global.json`,
`Directory.Build.props`, `Directory.Packages.props`, and `.config/dotnet-tools.json`.

Those files should remain authoritative. For example, SonarScanner should be restored
from the repository tool manifest rather than installed globally by these dotfiles.

## Security

Never commit secrets to this repository. Use GitHub Codespaces secrets or repository/environment
secrets for credentials.

## License

MIT
