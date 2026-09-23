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
├── .githooks/
│   └── pre-commit
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       └── validate.yml
├── bin/
│   ├── dotfiles-doctor
│   ├── dotfiles-update
│   ├── dotnet-bootstrap
│   ├── dotnet-context
│   ├── dotnet-deps
│   ├── dotnet-items
│   ├── dotnet-prop
│   ├── dotnet-props
│   ├── dotnet-repo-doctor
│   ├── dotnet-verify
│   ├── dotnet-why
│   └── git-root
├── git/
│   └── config
├── scripts/
│   └── validate-shell
├── shell/
│   ├── aliases.sh
│   ├── dotnet.sh
│   └── git.sh
├── tests/
│   ├── ci-policy.bats
│   ├── container-smoke.sh
│   ├── docker-context.sh
│   ├── dotnet-deps.bats
│   ├── dotnet-helpers.bats
│   ├── dotnet-verify.bats
│   ├── lifecycle.bats
│   ├── msbuild-helpers.bats
│   ├── update.bats
│   └── test_helper.bash
├── .dockerignore
├── .editorconfig
├── .gitattributes
├── .gitignore
├── AGENTS.md
├── AGENTS.pt-BR.md
├── Dockerfile.test
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

The installer is designed to be idempotent and must run as the normal development user, never as `root`. It:

- uses `${XDG_CONFIG_HOME:-$HOME/.config}/rodri-dotfiles` as the stable configuration location;
- links the shell helpers and Git configuration into that location;
- adds the dotfiles block to `~/.bashrc` only once and sources fragments only when readable;
- migrates the original repository-relative Git `include.path` to the stable configuration path;
- exposes scripts from `bin/` through `~/.local/bin`;
- refuses to replace pre-existing configuration or `~/.local/bin` paths unless they are already the exact managed symlinks expected by this repository;
- accepts only a regular, non-symlink `~/.bashrc`; managed markers must be exact, unique, and ordered, and changes are staged in a same-directory temporary file before atomic replacement while preserving existing permissions;
- configures this repository's local `core.hooksPath` to `.githooks` without changing the global hooks path used by other repositories.

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

The doctor validates the managed Bash block, PATH, configuration symlinks, Git `include.path`, this repository's local hook configuration, executable helper links, Bash/Git availability, and reports the detected .NET SDK when available. It returns a non-zero exit code when a managed configuration invariant is broken.

Update an existing clone safely:

```bash
dotfiles-update
```

`dotfiles-update` refuses to run when the worktree contains uncommitted changes, when the repository is in detached HEAD state, or when the current branch has no upstream. It fetches remote changes, applies only a fast-forward pull, reruns `install.sh`, and finishes with `dotfiles-doctor`. It never resets, stashes, or discards local work automatically.

Remove only configuration owned by this repository:

```bash
./uninstall.sh
```

The uninstaller removes the managed `~/.bashrc` block, exact Git include entries, this repository's managed local hooks path, and symlinks created by this repository. It deliberately leaves unrelated user files, Git settings, shell configuration, `~/.local/bin`, and non-managed files intact.

## Repository Git hooks

Running `install.sh` configures `.githooks` only for this dotfiles repository. It does not set a global `core.hooksPath`, so project-specific hooks in other .NET repositories remain untouched.

The `pre-commit` hook always runs Bash syntax validation. When ShellCheck and shfmt are installed locally it also runs those checks. Missing optional local tools produce a warning rather than blocking a commit; CI remains the authoritative gate and always installs and enforces both tools.

The hook and CI share the same validation entry point:

```bash
bash scripts/validate-shell
```

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

### `dotnet-deps`

Inspects NuGet dependency health without updating packages or editing project files. Supported diagnostics are `vulnerable`, `outdated`, and `deprecated`; `--include-transitive` adds transitive package references and `--json` requests the stable JSON report format when the resolved SDK supports it.

```bash
dotnet-deps vulnerable
dotnet-deps vulnerable --include-transitive --json
dotnet-deps outdated
dotnet-deps deprecated MyApp.slnx
```

The helper resolves the repository SDK before running the diagnostic. With .NET 10 or later it uses `dotnet package list`; with .NET 9 or earlier it uses `dotnet list package`. JSON output requires .NET SDK 7.0.200 or later. With exactly one root-level solution, that target is selected automatically; multiple root-level solutions require an explicit target.

The underlying package-list command can contact configured NuGet sources, and .NET 10 can restore automatically when required. The helper never updates package versions. Invalid invocation, unresolved SDK, unsupported JSON output, missing targets, or ambiguous solution selection return exit code `2`; otherwise the .NET CLI command's exit status is preserved.

### MSBuild evaluation helpers

The MSBuild helpers inspect the effective project configuration after MSBuild evaluation. They require .NET SDK 8 or later and do not run build targets. When invoked without a target, they recursively discover `.csproj`, `.fsproj`, and `.vbproj` files while ignoring common generated/build directories. Exactly one project is selected automatically; multiple projects require an explicit target.

`dotnet-prop` returns one evaluated property as plain text:

```bash
dotnet-prop TargetFramework
dotnet-prop ManagePackageVersionsCentrally src/MyApp/MyApp.csproj
```

`dotnet-props` prints a curated diagnostic snapshot including target frameworks, configuration, runtime identifiers, language/nullability settings, warning settings, Central Package Management, lock-file settings, deterministic/CI settings, documentation generation, and output path. Use `--json` to request the same snapshot in one native MSBuild JSON evaluation:

```bash
dotnet-props
dotnet-props --json src/MyApp/MyApp.csproj
```

`dotnet-items` returns evaluated MSBuild items and their metadata using MSBuild's native JSON output:

```bash
dotnet-items PackageReference
dotnet-items ProjectReference src/MyApp/MyApp.csproj
```

These helpers do not restore packages, modify project files, or execute targets. Invalid invocation, unresolved SDK, unsupported SDK, missing projects, invalid targets, or ambiguous project discovery return exit code `2`; otherwise the MSBuild command's status is preserved. In human-readable `dotnet-props` mode, a property-evaluation failure returns `1`.

### `dotnet-repo-doctor`

Performs a read-only diagnostic of the current .NET repository from any directory inside the Git worktree. It reports repository/branch state, requested and resolved SDKs, root-level solutions, project and test-project counts, declared target frameworks, Central Package Management, local tool manifests, and common repository configuration files.

```bash
dotnet-repo-doctor
```

Use `--json` when the result will be consumed by scripts or coding agents:

```bash
dotnet-repo-doctor --json
```

The helper does not restore packages, install tools, change project files, or perform network package audits. Exit code `0` means the diagnostic completed without a blocking problem, `1` means no .NET project or solution artifacts were detected, and `2` means the .NET CLI is unavailable, SDK resolution failed, or the command invocation is invalid.

### `dotnet-verify`

Runs a deterministic local preflight before a pull request or push. By default it restores project-local tools when a manifest exists, restores packages, builds without restoring again, verifies formatting without changing files, and runs tests without rebuilding or restoring again.

```bash
dotnet-verify
dotnet-verify --quick
dotnet-verify --no-test
dotnet-verify MyApp.slnx
```

`--quick` runs only restore and build. `--full` explicitly selects the default full verification. `--no-format` and `--no-test` skip those individual gates. With exactly one root-level `.sln` or `.slnx`, that solution is selected automatically; multiple solutions require an explicit target.

The helper does not install global tools or modify project configuration. Exit code `0` means every selected verification step passed, `1` means a restore/build/format/test step failed, and `2` means the invocation or environment cannot be resolved safely, such as a missing .NET CLI, incompatible SDK, missing target, or ambiguous solution selection.

### `dotnet-why`

Shows the dependency graph that explains why a NuGet package is present by wrapping `dotnet nuget why`.

```bash
dotnet-why Microsoft.CodeAnalysis.Common
dotnet-why Microsoft.CodeAnalysis.Common MyApp.slnx
dotnet-why --framework net8.0 Microsoft.CodeAnalysis.Common
```

`dotnet-why` requires .NET SDK 8.0.400 or later. It automatically selects a single root-level solution, requires an explicit target when multiple root-level solutions exist, and supports `--framework`/`-f` to restrict the graph to one target framework. It does not modify the repository. Invalid invocation, unsupported SDKs, missing targets, or ambiguous solution selection return exit code `2`; otherwise the `dotnet nuget why` exit status is preserved.

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

The repository validates static quality, observable behavior, and full installation lifecycle behavior.

Static validation:

- Bash syntax with `bash -n`;
- shell analysis with ShellCheck;
- deterministic shell formatting with `shfmt -d -i 2`.

Behavioral validation uses Bats and covers installation idempotency, stable configuration links, Git include and repository-hook management, doctor/uninstall behavior, safe `dotfiles-update` behavior, repository-root discovery, local .NET tool restore, single/multiple solution handling, read-only .NET repository diagnostics, the `dotnet-verify` preflight modes and failure behavior, NuGet dependency health/origin diagnostics across supported SDK command forms, and MSBuild property/item evaluation with safe project discovery.

A clean Ubuntu container additionally verifies that installation is rejected for `root`, succeeds and remains idempotent for a normal user, configures repository hooks, passes `dotfiles-doctor`, and can be safely uninstalled. The Docker test context is deny-by-default: only lifecycle inputs are allowed, and a dedicated sentinel test verifies that fictitious local `.env`/log files do not appear in the final filesystem or saved image layers.

Run locally after installing `bats`, `shellcheck`, and `shfmt`:

```bash
bash scripts/validate-shell
bats tests
docker build --file Dockerfile.test --tag dotfiles-lifecycle-test .
bash tests/docker-context.sh
```

These tools are development/CI dependencies only; `install.sh` does not install them into the personal environment.

### CI hardening

The validation workflow is intentionally hardened:

- every pull request targeting `main` runs validation, including documentation-only and `git/config` changes, so required checks are always reported;
- concurrency cancels older runs for the same ref when a newer commit arrives;
- shell validation has a five-minute timeout and clean-container validation has a ten-minute timeout;
- repository permissions are read-only;
- `actions/checkout` is pinned to a full commit SHA and does not persist credentials;
- the clean-container job runs only after static and Bats validation succeeds;
- Dependabot checks GitHub Actions dependencies weekly and groups available action updates into a single pull request.

Files:

```text
.github/workflows/validate.yml
.github/dependabot.yml
Dockerfile.test
```

Pull requests targeting `main` expose the stable check names `Shell validation` and `Clean container lifecycle`; the `main` ruleset can require those exact checks after this workflow version is merged and passing on `main`.

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
