#!/usr/bin/env bats

load test_helper

setup() {
  setup_dotfiles_test
  create_fake_dotnet
  create_git_project
}

@test "dotnet-prop discovers a single project from a nested directory" {
  mkdir -p "$PROJECT_ROOT/src/App" "$PROJECT_ROOT/src/App/obj/Generated"
  : >"$PROJECT_ROOT/src/App/App.csproj"
  : >"$PROJECT_ROOT/src/App/obj/Generated/Ignored.csproj"

  run bash -c 'cd "$1" && "$2" TargetFramework' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-prop"

  [ "$status" -eq 0 ]
  grep -Fxq "$PROJECT_ROOT|--version" "$DOTNET_LOG"
  grep -Fxq \
    "$PROJECT_ROOT|msbuild $PROJECT_ROOT/src/App/App.csproj -getProperty:TargetFramework -nologo" \
    "$DOTNET_LOG"
  ! grep -Fq 'Ignored.csproj' "$DOTNET_LOG"
}

@test "dotnet-prop accepts an explicit F# project target" {
  mkdir -p "$PROJECT_ROOT/src/App" "$PROJECT_ROOT/src/Other"
  : >"$PROJECT_ROOT/src/App/App.fsproj"
  : >"$PROJECT_ROOT/src/Other/Other.csproj"

  run bash -c 'cd "$1" && "$2" Nullable src/App/App.fsproj' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-prop"

  [ "$status" -eq 0 ]
  grep -Fxq \
    "$PROJECT_ROOT|msbuild $PROJECT_ROOT/src/App/App.fsproj -getProperty:Nullable -nologo" \
    "$DOTNET_LOG"
}

@test "dotnet-props emits the standard snapshot as one MSBuild JSON query" {
  mkdir -p "$PROJECT_ROOT/src/App"
  : >"$PROJECT_ROOT/src/App/App.csproj"

  run bash -c 'cd "$1" && "$2" --json' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"

  [ "$status" -eq 0 ]
  grep -Fq \
    "$PROJECT_ROOT|msbuild $PROJECT_ROOT/src/App/App.csproj -getProperty:TargetFramework,TargetFrameworks,Configuration,Platform,RuntimeIdentifier,RuntimeIdentifiers,LangVersion,Nullable,ImplicitUsings,TreatWarningsAsErrors,WarningsAsErrors,NoWarn,ManagePackageVersionsCentrally,CentralPackageTransitivePinningEnabled,RestorePackagesWithLockFile,ContinuousIntegrationBuild,Deterministic,GenerateDocumentationFile,OutputPath -nologo" \
    "$DOTNET_LOG"
}

@test "dotnet-props human output includes the curated property names" {
  mkdir -p "$PROJECT_ROOT/src/App"
  : >"$PROJECT_ROOT/src/App/App.vbproj"

  run bash -c 'cd "$1" && "$2"' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"

  [ "$status" -eq 0 ]
  assert_contains "$output" "Project: src/App/App.vbproj"
  assert_contains "$output" "TargetFramework:"
  assert_contains "$output" "ManagePackageVersionsCentrally:"
  assert_contains "$output" "OutputPath:"
}

@test "dotnet-items inspects evaluated items and preserves MSBuild JSON output" {
  mkdir -p "$PROJECT_ROOT/src/App"
  : >"$PROJECT_ROOT/src/App/App.csproj"

  run bash -c 'cd "$1" && "$2" ProjectReference' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-items"

  [ "$status" -eq 0 ]
  grep -Fxq \
    "$PROJECT_ROOT|msbuild $PROJECT_ROOT/src/App/App.csproj -getItem:ProjectReference -nologo" \
    "$DOTNET_LOG"
}

@test "MSBuild helpers refuse ambiguous project discovery" {
  mkdir -p "$PROJECT_ROOT/src/App" "$PROJECT_ROOT/src/Worker"
  : >"$PROJECT_ROOT/src/App/App.csproj"
  : >"$PROJECT_ROOT/src/Worker/Worker.csproj"

  run bash -c 'cd "$1" && "$2" TargetFramework' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-prop"

  [ "$status" -eq 2 ]
  assert_contains "$output" "Multiple project files were found"
  assert_contains "$output" "src/App/App.csproj"
  assert_contains "$output" "src/Worker/Worker.csproj"
  ! grep -Fq '|msbuild ' "$DOTNET_LOG"
}

@test "MSBuild helpers reject SDKs older than .NET 8" {
  mkdir -p "$PROJECT_ROOT/src/App"
  : >"$PROJECT_ROOT/src/App/App.csproj"
  export FAKE_DOTNET_VERSION="7.0.410"

  run bash -c 'cd "$1" && "$2" PackageReference' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-items"

  [ "$status" -eq 2 ]
  assert_contains "$output" "MSBuild evaluation helpers require .NET SDK 8 or later"
  ! grep -Fq '|msbuild ' "$DOTNET_LOG"
}

@test "MSBuild helpers reject non-project explicit targets" {
  : >"$PROJECT_ROOT/App.slnx"

  run bash -c 'cd "$1" && "$2" TargetFramework App.slnx' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-prop"

  [ "$status" -eq 2 ]
  assert_contains "$output" "target must be a .csproj, .fsproj, or .vbproj file"
  ! grep -Fq '|msbuild ' "$DOTNET_LOG"
}
