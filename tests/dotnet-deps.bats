#!/usr/bin/env bats

load test_helper

setup() {
  setup_dotfiles_test
  create_fake_dotnet
  create_git_project
}

@test "dotnet-deps uses noun-first package list on .NET 10" {
  : >"$PROJECT_ROOT/App.slnx"
  export FAKE_DOTNET_VERSION="10.0.400"

  run bash -c 'cd "$1" && "$2" vulnerable --include-transitive --json' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-deps"

  [ "$status" -eq 0 ]
  grep -Fxq "$PROJECT_ROOT|--version" "$DOTNET_LOG"
  grep -Fxq \
    "$PROJECT_ROOT|package list --project $PROJECT_ROOT/App.slnx --vulnerable --include-transitive --format json --output-version 1" \
    "$DOTNET_LOG"
}

@test "dotnet-deps uses verb-first list package on .NET 9 and earlier" {
  : >"$PROJECT_ROOT/App.slnx"
  export FAKE_DOTNET_VERSION="9.0.300"

  run bash -c 'cd "$1" && "$2" outdated' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-deps"

  [ "$status" -eq 0 ]
  grep -Fxq "$PROJECT_ROOT|list $PROJECT_ROOT/App.slnx package --outdated" "$DOTNET_LOG"
}

@test "dotnet-deps supports deprecated package diagnostics" {
  : >"$PROJECT_ROOT/App.slnx"
  export FAKE_DOTNET_VERSION="8.0.400"

  run bash -c 'cd "$1" && "$2" deprecated --include-transitive' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-deps"

  [ "$status" -eq 0 ]
  grep -Fxq \
    "$PROJECT_ROOT|list $PROJECT_ROOT/App.slnx package --deprecated --include-transitive" \
    "$DOTNET_LOG"
}

@test "dotnet-deps rejects JSON output on SDKs older than 7.0.200" {
  : >"$PROJECT_ROOT/App.slnx"
  export FAKE_DOTNET_VERSION="7.0.100"

  run bash -c 'cd "$1" && "$2" vulnerable --json' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-deps"

  [ "$status" -eq 2 ]
  assert_contains "$output" "--json requires .NET SDK 7.0.200 or later"
  ! grep -Fq '|list ' "$DOTNET_LOG"
  ! grep -Fq '|package list ' "$DOTNET_LOG"
}

@test "dotnet-deps refuses ambiguous root solutions" {
  : >"$PROJECT_ROOT/App.slnx"
  : >"$PROJECT_ROOT/Samples.sln"

  run bash -c 'cd "$1" && "$2" outdated' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-deps"

  [ "$status" -eq 2 ]
  assert_contains "$output" "Multiple solution files were found"
  assert_contains "$output" "App.slnx"
  assert_contains "$output" "Samples.sln"
  ! grep -Fq '|package list ' "$DOTNET_LOG"
  ! grep -Fq '|list ' "$DOTNET_LOG"
}

@test "dotnet-deps accepts an explicit project target" {
  mkdir -p "$PROJECT_ROOT/src/App"
  : >"$PROJECT_ROOT/src/App/App.csproj"
  export FAKE_DOTNET_VERSION="10.0.400"

  run bash -c 'cd "$1" && "$2" vulnerable src/App/App.csproj' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-deps"

  [ "$status" -eq 0 ]
  grep -Fxq \
    "$PROJECT_ROOT|package list --project $PROJECT_ROOT/src/App/App.csproj --vulnerable" \
    "$DOTNET_LOG"
}

@test "dotnet-why shows dependency origin with an optional framework" {
  : >"$PROJECT_ROOT/App.slnx"
  export FAKE_DOTNET_VERSION="8.0.400"

  run bash -c 'cd "$1" && "$2" Microsoft.CodeAnalysis.Common --framework net8.0' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-why"

  [ "$status" -eq 0 ]
  grep -Fxq \
    "$PROJECT_ROOT|nuget why $PROJECT_ROOT/App.slnx Microsoft.CodeAnalysis.Common --framework net8.0" \
    "$DOTNET_LOG"
}

@test "dotnet-why selects the only project when no root solution exists" {
  mkdir -p "$PROJECT_ROOT/src/App"
  : >"$PROJECT_ROOT/src/App/App.csproj"
  export FAKE_DOTNET_VERSION="8.0.400"

  run bash -c 'cd "$1" && "$2" Microsoft.CodeAnalysis.Common' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-why"

  [ "$status" -eq 0 ]
  grep -Fxq \
    "$PROJECT_ROOT|nuget why $PROJECT_ROOT/src/App/App.csproj Microsoft.CodeAnalysis.Common" \
    "$DOTNET_LOG"
}

@test "dotnet-why refuses ambiguous projects when no root solution exists" {
  mkdir -p "$PROJECT_ROOT/src/App" "$PROJECT_ROOT/src/Worker"
  : >"$PROJECT_ROOT/src/App/App.csproj"
  : >"$PROJECT_ROOT/src/Worker/Worker.csproj"
  export FAKE_DOTNET_VERSION="8.0.400"

  run bash -c 'cd "$1" && "$2" Microsoft.CodeAnalysis.Common' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-why"

  [ "$status" -eq 2 ]
  assert_contains "$output" "multiple project files exist"
  assert_contains "$output" "src/App/App.csproj"
  assert_contains "$output" "src/Worker/Worker.csproj"
  ! grep -Fq '|nuget why ' "$DOTNET_LOG"
}

@test "dotnet-why rejects SDKs older than 8.0.400" {
  : >"$PROJECT_ROOT/App.slnx"
  export FAKE_DOTNET_VERSION="8.0.399"

  run bash -c 'cd "$1" && "$2" Microsoft.CodeAnalysis.Common' _ \
    "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-why"

  [ "$status" -eq 2 ]
  assert_contains "$output" "dotnet nuget why requires .NET SDK 8.0.400 or later"
  ! grep -Fq '|nuget why ' "$DOTNET_LOG"
}
