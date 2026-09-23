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
├── lib/
│   ├── dotnet-common.sh
│   └── dotnet-props-format.py
├── scripts/
│   ├── install-security-tools
│   ├── scan-tracked-secrets
│   ├── security-scan
│   └── validate-shell
├── shell/
│   ├── aliases.sh
│   ├── dotnet.sh
│   └── git.sh
├── tests/
│   ├── ci-policy.bats
│   ├── container-smoke.sh
│   ├── docker-context.sh
│   ├── dotnet-common.bats
│   ├── dotnet-deps.bats
│   ├── dotnet-helpers.bats
│   ├── dotnet-verify.bats
│   ├── lifecycle.bats
│   ├── msbuild-helpers.bats
│   ├── security-scans.sh
│   ├── update.bats
│   └── test_helper.bash
├── .dockerignore
├── .editorconfig
├── .gitattributes
├── .gitleaks.toml
├── .gitignore
├── .hadolint.yaml
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

`dotfiles-update` treats the update source as a trust boundary. It runs only from the `main` distribution branch tracking `origin/main`, and `origin` must resolve without URL rewriting to this repository's official GitHub HTTPS or SSH URL. After a hook-disabled fetch, the helper verifies that `FETCH_HEAD` is exactly `origin/main`, that the target is a fast-forward from the current revision, and that the fetched revision still contains executable `install.sh` and `bin/dotfiles-doctor`. Only then does it apply the fast-forward with Git hooks disabled, verify that `HEAD` matches the validated revision, run the updated installer, and finish with `dotfiles-doctor`. It never resets, stashes, or discards local work automatically.

This policy authenticates the configured distribution route; it does **not** claim that Git transport or GitHub's UI "Verified" badge proves the fetched code is benign. Commit/tag signature enforcement is not enabled because this repository currently has no local signing trust root that can be verified consistently in Codespaces/Linux clones. Repository rules and required CI protect changes entering `main`, while the updater independently restricts which remote/branch it will execute.

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

## Trust boundaries for .NET helpers

These helpers are convenience wrappers, not a security sandbox. A repository being a Git worktree does not make its project files, imports, package sources, tools, build logic, or tests trustworthy.

| Helper group | What it does | Important side effects / trust boundary | Recommended trust level |
| --- | --- | --- | --- |
| `dotnet-context`, `dotnet-repo-doctor`, `dotnet-sdk`, `dotnet-tools`, `dotnet-solutions` | Reads repository metadata and configuration; some commands also invoke the .NET host for SDK/tool information. | No explicit package restore, build, or test is requested by these helpers. However, `global.json` and tool metadata still come from the target repository, and invoking `dotnet` is not equivalent to plain-text inspection. | Suitable for repositories you are willing to inspect with the installed .NET host. For unknown code, prefer plain file inspection first. |
| `dotnet-prop`, `dotnet-props`, `dotnet-items` | Invokes `dotnet msbuild` to evaluate properties/items without intentionally running a build target. | MSBuild evaluation loads project files, SDK resolution and imported files such as `Directory.Build.props`/`Directory.Build.targets` and other imports. “No build” does not mean isolated or safe evaluation of an untrusted project. | Treat the repository and its MSBuild inputs as trusted before running. |
| `dotnet-deps`, `dotnet-why` | Queries package/dependency information through the .NET CLI. | May evaluate project metadata and use existing restore assets. `dotnet-deps` can contact configured NuGet sources and, on supported SDKs, may restore automatically. Package-source credentials and network access can therefore be in scope. | Use only after reviewing package sources/configuration and deciding the repository is appropriate to query with your credentials/network. |
| `dotnet-bootstrap` | Runs local tool restore when a tool manifest exists, then restores NuGet packages. | Can access package feeds, consume `NuGet.config`, restore project dependencies, evaluate MSBuild restore logic, and download repository-declared local tools. | Trusted repositories only. Review manifests and package sources before use. |
| `dotnet-verify` | Restores tools/packages, builds, optionally runs formatting verification, and runs tests. | Build/test can load MSBuild tasks, analyzers, source generators, format tooling and test code supplied by the repository. This is code execution with the current user's filesystem, environment, network and credentials unless the surrounding environment restricts them. | Trusted repositories only; for external code, run only after explicit review/approval in a constrained environment. |

Project-controlled inputs include at least `global.json`, project/solution files, `Directory.Build.props`, `Directory.Build.targets`, other MSBuild imports, `Directory.Packages.props`, `.config/dotnet-tools.json`, and repository/user `NuGet.config` files. Review the relevant inputs before restore, MSBuild evaluation, build, formatting, or test execution.

For external or not-yet-trusted repositories:

- prefer plain-text inspection (`cat`, `grep`, `find`, source review) before invoking project-aware tooling;
- use a disposable container, VM, or Codespace without personal/repository/cloud secrets;
- restrict filesystem permissions and network access when practical;
- avoid exposing authenticated NuGet feeds or other package-source credentials until the repository and its configuration have been reviewed;
- require an explicit human decision before automation performs MSBuild evaluation, tool/package restore, build, formatting, or tests.

The helpers intentionally keep their existing non-interactive interfaces. They do not add prompts and they do not claim to provide process, filesystem, credential, or network isolation.

The seven repository-aware executable helpers share the source-only Bash library `lib/dotnet-common.sh` for Git-root discovery, SDK checks, solution/project discovery, and path resolution. Public commands retain their existing argument parsing and intentional target-selection differences. The helpers resolve their own script path before sourcing the library, including when invoked through managed `~/.local/bin` symlinks. Keep `lib/` alongside `bin/` when copying the dotfiles repository.

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
- shell/security validation and clean-container validation each have bounded ten-minute timeouts;
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

Pull requests targeting `main` expose the stable check names `Shell validation` and `Clean container lifecycle`; the active `main` ruleset requires both checks with strict status-check enforcement.

### Security scanning

The required `Shell validation` check also enforces four security scanners before Bats:

| Scanner | Pinned version | CI scope | Failure policy |
| --- | ---: | --- | --- |
| Gitleaks | 8.30.1 | All tracked blobs from the current `HEAD` commit, including files marked `export-ignore`; the PR gate does not scan prior Git history, `.git` metadata or external Git LFS payloads. | Any finding fails the check. Output uses 100% secret redaction and no report artifact is uploaded. |
| actionlint | 1.7.12 | All GitHub Actions workflows discovered in the checkout. | Any syntax/semantic finding fails the check. |
| zizmor | 1.30.1 | Local repository configuration, including workflows/Dependabot inputs; forced offline with strict input collection. | Any reported audit finding or parse failure fails the check. No GitHub token is supplied. |
| Hadolint | 2.15.1 | `Dockerfile.test`. | Findings at warning severity or above fail. `DL3008` is explicitly ignored because pinning Ubuntu apt package versions would make the ephemeral smoke-test image brittle against normal repository updates. |

`scripts/install-security-tools` downloads Linux x86_64 or arm64 release binaries and verifies their pinned SHA-256 digests before installation. The CI does not use third-party scanner actions and therefore does not grant scanner-specific GitHub permissions or production secrets. Fork pull requests use the same read-only workflow.

Gitleaks extends its built-in rules with one repository-specific synthetic rule. `tests/security-scans.sh` creates a synthetic finding in temporary directories, confirms exit code 1 and the expected rule identifier rather than an arbitrary scanner error, and verifies that the candidate value is absent from scanner output. A temporary committed Git fixture with `export-ignore` also proves that the production `scripts/scan-tracked-secrets` detects tracked blobs omitted by `git archive`. No real credential is used; the fixtures and captured output are removed after the test.

False-positive handling is intentionally explicit: do not suppress a finding broadly to make CI pass. Prefer fixing the source, narrowing a scanner configuration to the smallest justified rule/path, and documenting the exception in the configuration and pull request.

Run the same security gates locally on supported Linux x86_64/arm64 environments:

```bash
bash scripts/install-security-tools
bash scripts/security-scan
```

For an occasional full-history secret audit, run Gitleaks explicitly against Git history after reviewing the output-handling implications:

```bash
gitleaks git --config .gitleaks.toml --no-banner --no-color --redact=100 .
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
