#!/usr/bin/env bats

load test_helper

setup() {
  setup_dotfiles_test
  create_fake_dotnet
  create_git_project
}

@test "dotnet-context resolves repository metadata from a nested directory" {
  cat >"$PROJECT_ROOT/global.json" <<'EOF'
{
  "sdk": {
    "version": "10.0.400"
  }
}
EOF
  : >"$PROJECT_ROOT/Directory.Build.props"
  : >"$PROJECT_ROOT/Directory.Packages.props"
  mkdir -p "$PROJECT_ROOT/.config"
  printf '{}\n' >"$PROJECT_ROOT/.config/dotnet-tools.json"
  : >"$PROJECT_ROOT/App.slnx"

  run bash -c 'cd "$1" && "$2"' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-context"

  [ "$status" -eq 0 ]
  assert_contains "$output" "$PROJECT_ROOT"
  assert_contains "$output" "SDK: 10.0.400"
  assert_contains "$output" "global.json: yes"
  assert_contains "$output" "Directory.Build.props: yes"
  assert_contains "$output" "Central Package Management: yes"
  assert_contains "$output" "Local tool manifest: yes"
  assert_contains "$output" "App.slnx"

  grep -Fxq "$PROJECT_ROOT|--version" "$DOTNET_LOG"
}

@test "dotnet-bootstrap restores local tools and the only solution automatically" {
  mkdir -p "$PROJECT_ROOT/.config"
  printf '{}\n' >"$PROJECT_ROOT/.config/dotnet-tools.json"
  : >"$PROJECT_ROOT/App.slnx"

  run bash -c 'cd "$1" && "$2"' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-bootstrap"

  [ "$status" -eq 0 ]
  assert_contains "$output" "Repository ready."

  grep -Fxq "$PROJECT_ROOT|tool restore" "$DOTNET_LOG"
  grep -Fq "restore $PROJECT_ROOT/App.slnx" "$DOTNET_LOG"
}

@test "dotnet-bootstrap refuses to choose between multiple solutions" {
  : >"$PROJECT_ROOT/App.slnx"
  : >"$PROJECT_ROOT/Samples.slnx"

  run bash -c 'cd "$1" && "$2"' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-bootstrap"

  [ "$status" -eq 2 ]
  assert_contains "$output" "Multiple solution files were found"
  assert_contains "$output" "App.slnx"
  assert_contains "$output" "Samples.slnx"
  [ ! -s "$DOTNET_LOG" ]
}

@test "dotnet-bootstrap accepts an explicit solution when multiple solutions exist" {
  : >"$PROJECT_ROOT/App.slnx"
  : >"$PROJECT_ROOT/Samples.slnx"

  run bash -c 'cd "$1" && "$2" Samples.slnx' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-bootstrap"

  [ "$status" -eq 0 ]
  grep -Fq "restore $PROJECT_ROOT/Samples.slnx" "$DOTNET_LOG"
}

@test "dotnet-repo-doctor reports repository, SDK, projects, frameworks, and configuration" {
  cat >"$PROJECT_ROOT/global.json" <<'EOF'
{
  "sdk": {
    "version": "10.0.400"
  }
}
EOF

  cat >"$PROJECT_ROOT/Directory.Packages.props" <<'EOF'
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
</Project>
EOF

  : >"$PROJECT_ROOT/Directory.Build.props"
  : >"$PROJECT_ROOT/.editorconfig"
  : >"$PROJECT_ROOT/App.slnx"
  mkdir -p "$PROJECT_ROOT/.config" "$PROJECT_ROOT/src/App" "$PROJECT_ROOT/tests/App.Tests"
  printf '{}\n' >"$PROJECT_ROOT/.config/dotnet-tools.json"

  cat >"$PROJECT_ROOT/src/App/App.csproj" <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
</Project>
EOF

  cat >"$PROJECT_ROOT/tests/App.Tests/App.Tests.csproj" <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFrameworks>net10.0;net9.0</TargetFrameworks>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
</Project>
EOF

  run bash -c 'cd "$1" && "$2"' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-repo-doctor"

  [ "$status" -eq 0 ]
  assert_contains "$output" "Root: $PROJECT_ROOT"
  assert_contains "$output" "Requested SDK: 10.0.400"
  assert_contains "$output" "Resolved SDK: 10.0.400"
  assert_contains "$output" "App.slnx"
  assert_contains "$output" "Total: 2"
  assert_contains "$output" "Tests: 1"
  assert_contains "$output" "Declared frameworks: net10.0, net9.0"
  assert_contains "$output" "Central Package Management: yes"
  assert_contains "$output" "Local tool manifest: yes"
  assert_contains "$output" ".editorconfig: yes"
  assert_contains "$output" "healthy"

  grep -Fxq "$PROJECT_ROOT|--version" "$DOTNET_LOG"
}

@test "dotnet-repo-doctor emits machine-readable JSON" {
  : >"$PROJECT_ROOT/App.slnx"
  mkdir -p "$PROJECT_ROOT/src/App"

  cat >"$PROJECT_ROOT/src/App/App.csproj" <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
</Project>
EOF

  run bash -c 'cd "$1" && "$2" --json' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-repo-doctor"

  [ "$status" -eq 0 ]
  assert_contains "$output" '"status":"healthy"'
  assert_contains "$output" '"resolvedSdk":"10.0.400"'
  assert_contains "$output" '"solutions":["App.slnx"]'
  assert_contains "$output" '"count":1'
  assert_contains "$output" '"declaredFrameworks":["net10.0"]'
}

@test "dotnet-repo-doctor warns when no .NET repository artifacts are detected" {
  run bash -c 'cd "$1" && "$2"' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-repo-doctor"

  [ "$status" -eq 1 ]
  assert_contains "$output" "Total: 0"
  assert_contains "$output" "(none)"
  assert_contains "$output" "warning"
}
