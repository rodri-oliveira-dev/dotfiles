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

@test "dotnet-props preserves an explicit target when option separator is last" {
  mkdir -p "$PROJECT_ROOT/src/App" "$PROJECT_ROOT/src/Other"
  : >"$PROJECT_ROOT/src/App/App.csproj"
  : >"$PROJECT_ROOT/src/Other/Other.csproj"

  run bash -c 'cd "$1" && "$2" --json src/App/App.csproj --' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"

  [ "$status" -eq 0 ]
  grep -Fq \
    "$PROJECT_ROOT|msbuild $PROJECT_ROOT/src/App/App.csproj -getProperty:TargetFramework,TargetFrameworks,Configuration,Platform,RuntimeIdentifier,RuntimeIdentifiers,LangVersion,Nullable,ImplicitUsings,TreatWarningsAsErrors,WarningsAsErrors,NoWarn,ManagePackageVersionsCentrally,CentralPackageTransitivePinningEnabled,RestorePackagesWithLockFile,ContinuousIntegrationBuild,Deterministic,GenerateDocumentationFile,OutputPath -nologo" \
    "$DOTNET_LOG"
  ! grep -Fq "$PROJECT_ROOT/src/Other/Other.csproj" "$DOTNET_LOG"
}

@test "dotnet-props rejects a second target after option separator" {
  mkdir -p "$PROJECT_ROOT/src/App" "$PROJECT_ROOT/src/Other"
  : >"$PROJECT_ROOT/src/App/App.csproj"
  : >"$PROJECT_ROOT/src/Other/Other.csproj"

  run bash -c 'cd "$1" && "$2" src/App/App.csproj -- src/Other/Other.csproj' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"

  [ "$status" -eq 2 ]
  assert_contains "$output" "only one target may be specified"
  ! grep -Fq '|msbuild ' "$DOTNET_LOG"
}


@test "dotnet-props human snapshot uses one MSBuild evaluation with all 19 ordered names" {
  mkdir -p "$PROJECT_ROOT/src/My App"
  : >"$PROJECT_ROOT/src/My App/My App.csproj"

  run bash -c 'cd "$1" && "$2" "src/My App/My App.csproj"' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"

  [ "$status" -eq 0 ]
  assert_contains "$output" "Project: src/My App/My App.csproj"
  assert_contains "$output" "TargetFramework:                       net10.0"
  assert_contains "$output" "TargetFrameworks:                      "
  assert_contains "$output" "OutputPath:                            bin/Debug/"
  [ "$(grep -c '|msbuild ' "$DOTNET_LOG")" -eq 1 ]
  grep -Fq "$PROJECT_ROOT|msbuild $PROJECT_ROOT/src/My App/My App.csproj -getProperty:TargetFramework,TargetFrameworks,Configuration,Platform,RuntimeIdentifier,RuntimeIdentifiers,LangVersion,Nullable,ImplicitUsings,TreatWarningsAsErrors,WarningsAsErrors,NoWarn,ManagePackageVersionsCentrally,CentralPackageTransitivePinningEnabled,RestorePackagesWithLockFile,ContinuousIntegrationBuild,Deterministic,GenerateDocumentationFile,OutputPath -nologo" "$DOTNET_LOG"

  actual_labels="$(printf '%s\n' "$output" | grep -E '^[A-Za-z]+:' | grep -v '^Project:' | sed 's/:.*//' | paste -sd, -)"
  expected_labels='TargetFramework,TargetFrameworks,Configuration,Platform,RuntimeIdentifier,RuntimeIdentifiers,LangVersion,Nullable,ImplicitUsings,TreatWarningsAsErrors,WarningsAsErrors,NoWarn,ManagePackageVersionsCentrally,CentralPackageTransitivePinningEnabled,RestorePackagesWithLockFile,ContinuousIntegrationBuild,Deterministic,GenerateDocumentationFile,OutputPath'
  [ "$actual_labels" = "$expected_labels" ]
}

@test "dotnet-props JSON remains the native MSBuild response with one evaluation" {
  : >"$PROJECT_ROOT/Special.csproj"
  run bash -c 'cd "$1" && "$2" --json Special.csproj' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"

  [ "$status" -eq 0 ]
  [[ "$output" == '{"Properties":'* ]]
  ! [[ "$output" == *"Project:"* ]]
  printf '%s\n' "$output" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["Properties"]["TargetFramework"] == "net10.0"'
  [ "$(grep -c '|msbuild ' "$DOTNET_LOG")" -eq 1 ]
}

@test "dotnet-props preserves empty values, quotes, unicode and embedded line breaks" {
  : >"$PROJECT_ROOT/Special.csproj"
  export FAKE_MSBUILD_RESPONSE='{"Properties":{"TargetFramework":"net10.0","TargetFrameworks":"","Configuration":"Debug","Platform":"AnyCPU","RuntimeIdentifier":"","RuntimeIdentifiers":"","LangVersion":"latest","Nullable":"enable","ImplicitUsings":"enable","TreatWarningsAsErrors":"false","WarningsAsErrors":"","NoWarn":"CA1000,\nCA2000","ManagePackageVersionsCentrally":"false","CentralPackageTransitivePinningEnabled":"false","RestorePackagesWithLockFile":"false","ContinuousIntegrationBuild":"false","Deterministic":"true","GenerateDocumentationFile":"false","OutputPath":"bin/My Folder/\"quoted\" é\\tmp"}}'

  run bash -c 'cd "$1" && "$2" Special.csproj' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"

  [ "$status" -eq 0 ]
  assert_contains "$output" "TargetFrameworks:                      "
  assert_contains "$output" "NoWarn:                                CA1000,"
  assert_contains "$output" "CA2000"
  assert_contains "$output" 'bin/My Folder/"quoted" é\tmp'
  [ "$(grep -c '|msbuild ' "$DOTNET_LOG")" -eq 1 ]
}

@test "dotnet-props evaluation failure returns 1 without partial report" {
  : >"$PROJECT_ROOT/Special.csproj"
  export FAKE_MSBUILD_EXIT=23
  export FAKE_MSBUILD_RESPONSE='Project: misleading partial report'

  run bash -c 'cd "$1" && "$2" Special.csproj' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"

  [ "$status" -eq 1 ]
  assert_contains "$output" "Error: failed to evaluate MSBuild properties."
  ! [[ "$output" == *"Project:"* ]]
  ! [[ "$output" == *"TargetFramework:"* ]]
  [ "$(grep -c '|msbuild ' "$DOTNET_LOG")" -eq 1 ]
}

@test "dotnet-props invalid JSON and missing properties emit no partial report" {
  : >"$PROJECT_ROOT/Special.csproj"
  for response in 'not-json' '{"Properties":{"TargetFramework":"net10.0"}}'; do
    export FAKE_MSBUILD_RESPONSE="$response"

    run bash -c 'cd "$1" && "$2" Special.csproj' _ \
      "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"

    [ "$status" -eq 1 ]
    assert_contains "$output" "Error: failed to format evaluated MSBuild properties."
    ! [[ "$output" == *"Project:"* ]]
    ! [[ "$output" == *"TargetFramework:"* ]]
  done
  [ "$(grep -c '|msbuild ' "$DOTNET_LOG")" -eq 2 ]
}

@test "dotnet-props JSON does not require the human-mode Python parser" {
  : >"$PROJECT_ROOT/Special.csproj"
  cat >"$FAKE_BIN/python3" <<'EOF'
#!/usr/bin/env bash
exit 77
EOF
  chmod +x "$FAKE_BIN/python3"

  run bash -c 'cd "$1" && "$2" --json Special.csproj' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"

  [ "$status" -eq 0 ]
  [[ "$output" == '{"Properties":'* ]]
  [ "$(grep -c '|msbuild ' "$DOTNET_LOG")" -eq 1 ]

  run bash -c 'cd "$1" && "$2" Special.csproj' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-props"
  [ "$status" -eq 1 ]
  assert_contains "$output" "Error: failed to format evaluated MSBuild properties."
  ! [[ "$output" == *"Project:"* ]]
}

@test "dotnet-props evaluates a real minimal project when SDK 8+ is available" {
  local real_dotnet
  real_dotnet="$(PATH="$ORIGINAL_PATH" command -v dotnet || true)"
  if [[ -z "$real_dotnet" ]]; then
    skip "No real dotnet executable available in the test runner."
  fi

  local actual_version
  actual_version="$(PATH="$ORIGINAL_PATH" "$real_dotnet" --version 2>/dev/null || true)"
  local major
  major="$(printf '%s' "$actual_version" | cut -d. -f1)"
  if ! [[ "$major" =~ ^[0-9]+$ ]] || ((major < 8)); then
    skip "No compatible real dotnet SDK 8+ available in the test runner."
  fi

  local real_project="$BATS_TEST_TMPDIR/real dotnet fixture"
  mkdir -p "$real_project"
  cat >"$real_project/Fixture.csproj" <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <OutputPath>bin/Space Folder/</OutputPath>
  </PropertyGroup>
</Project>
EOF

  run env PATH="$ORIGINAL_PATH" DOTNET_CLI_HOME="$HOME" DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    "$REPO_ROOT/bin/dotnet-props" --json "$real_project/Fixture.csproj"
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | python3 -c 'import json,sys; assert json.load(sys.stdin)["Properties"]["TargetFramework"] == "net8.0"'

  run env PATH="$ORIGINAL_PATH" DOTNET_CLI_HOME="$HOME" DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    "$REPO_ROOT/bin/dotnet-props" "$real_project/Fixture.csproj"
  [ "$status" -eq 0 ]
  assert_contains "$output" "TargetFramework:                       net8.0"
  assert_contains "$output" "OutputPath:"
  assert_contains "$output" "Space Folder"
}
