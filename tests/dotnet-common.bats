#!/usr/bin/env bats

load test_helper

setup() {
  setup_dotfiles_test
  create_fake_dotnet
  create_git_project "repository with spaces"
}

@test "all seven helpers load the common library from the source tree" {
  : >"$PROJECT_ROOT/App.slnx"
  : >"$PROJECT_ROOT/App.csproj"

  run bash -c 'cd "$1" && "$2" App.slnx --ignore-failed-sources' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-bootstrap"
  [ "$status" -eq 0 ]
  grep -Fq "$PROJECT_ROOT|restore $PROJECT_ROOT/App.slnx --ignore-failed-sources" "$DOTNET_LOG"

  run bash -c 'cd "$1" && "$2" vulnerable App.slnx' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-deps"
  [ "$status" -eq 0 ]

  run bash -c 'cd "$1" && "$2" Microsoft.Extensions.Logging App.slnx' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-why"
  [ "$status" -eq 0 ]

  run bash -c 'cd "$1" && "$2" --quick App.slnx' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-verify"
  [ "$status" -eq 0 ]

  run bash -c 'cd "$1" && "$2" TargetFramework App.csproj' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-prop"
  [ "$status" -eq 0 ]

  run bash -c 'cd "$1" && "$2" --json App.csproj' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"
  [ "$status" -eq 0 ]

  run bash -c 'cd "$1" && "$2" PackageReference App.csproj' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-items"
  [ "$status" -eq 0 ]
}

@test "helper invoked from a chained relative symlink still resolves its sibling library" {
  mkdir -p "$BATS_TEST_TMPDIR/links with spaces" "$PROJECT_ROOT/src/My Project"
  : >"$PROJECT_ROOT/src/My Project/My Project.fsproj"

  ln -s "$REPO_ROOT/bin/dotnet-prop" "$BATS_TEST_TMPDIR/links with spaces/first"
  ln -s first "$BATS_TEST_TMPDIR/links with spaces/second"

  run bash -c 'cd "$1" && "$2" Nullable "src/My Project/My Project.fsproj"' _ \
    "$PROJECT_ROOT/src/nested" "$BATS_TEST_TMPDIR/links with spaces/second"

  [ "$status" -eq 0 ]
  grep -Fxq "$PROJECT_ROOT|msbuild $PROJECT_ROOT/src/My Project/My Project.fsproj -getProperty:Nullable -nologo" "$DOTNET_LOG"
}

@test "helper invoked via installed PATH symlink preserves the explicit project path with spaces" {
  mkdir -p "$HOME/.local/bin" "$PROJECT_ROOT/src/My Project"
  : >"$PROJECT_ROOT/src/My Project/My Project.csproj"
  ln -s "$REPO_ROOT/bin/dotnet-prop" "$HOME/.local/bin/dotnet-prop"

  run bash -c 'cd "$1" && "$2" TargetFramework "src/My Project/My Project.csproj"' _ \
    "$PROJECT_ROOT/src/nested" "$HOME/.local/bin/dotnet-prop"

  [ "$status" -eq 0 ]
  grep -Fxq "$PROJECT_ROOT|msbuild $PROJECT_ROOT/src/My Project/My Project.csproj -getProperty:TargetFramework -nologo" "$DOTNET_LOG"
}

@test "non-git directory still resolves as repository root for explicit target" {
  NON_GIT="$BATS_TEST_TMPDIR/plain .NET folder"
  mkdir -p "$NON_GIT"
  : >"$NON_GIT/Plain.csproj"

  run bash -c 'cd "$1" && "$2" TargetFramework Plain.csproj' _ "$NON_GIT" "$REPO_ROOT/bin/dotnet-prop"

  [ "$status" -eq 0 ]
  grep -Fxq "$NON_GIT|msbuild $NON_GIT/Plain.csproj -getProperty:TargetFramework -nologo" "$DOTNET_LOG"
}

@test "MSBuild helpers keep SDK incompatibility as an environment exit code" {
  : >"$PROJECT_ROOT/App.csproj"
  export FAKE_DOTNET_VERSION="7.0.410"

  for helper in dotnet-prop dotnet-props dotnet-items; do
    case "$helper" in
    dotnet-prop) args=(TargetFramework App.csproj) ;;
    dotnet-props) args=(--json App.csproj) ;;
    dotnet-items) args=(PackageReference App.csproj) ;;
    esac

    run bash -c 'cd "$1"; shift; "$@"' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/$helper" "${args[@]}"
    [ "$status" -eq 2 ]
    assert_contains "$output" "MSBuild evaluation helpers require .NET SDK 8 or later"
  done

  ! grep -Fq '|msbuild ' "$DOTNET_LOG"
}

@test "why keeps its project fallback while deps and verify keep solution-only discovery" {
  mkdir -p "$PROJECT_ROOT/src/My Project"
  : >"$PROJECT_ROOT/src/My Project/My Project.csproj"

  run bash -c 'cd "$1" && "$2" Newtonsoft.Json' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-why"
  [ "$status" -eq 0 ]
  grep -Fq "nuget why $PROJECT_ROOT/src/My Project/My Project.csproj Newtonsoft.Json" "$DOTNET_LOG"

  run bash -c 'cd "$1" && "$2" outdated' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-deps"
  [ "$status" -eq 0 ]
  grep -Fq "$PROJECT_ROOT|package list --outdated" "$DOTNET_LOG"

  run bash -c 'cd "$1" && "$2" --quick' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-verify"
  [ "$status" -eq 0 ]
  grep -Fxq "$PROJECT_ROOT|restore" "$DOTNET_LOG"
}
