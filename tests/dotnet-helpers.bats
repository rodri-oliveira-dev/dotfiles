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
  assert_output_contains "$PROJECT_ROOT"
  assert_output_contains "SDK: 10.0.400"
  assert_output_contains "global.json: yes"
  assert_output_contains "Directory.Build.props: yes"
  assert_output_contains "Central Package Management: yes"
  assert_output_contains "Local tool manifest: yes"
  assert_output_contains "App.slnx"

  grep -Fxq "$PROJECT_ROOT|--version" "$DOTNET_LOG"
}

@test "dotnet-bootstrap restores local tools and the only solution automatically" {
  mkdir -p "$PROJECT_ROOT/.config"
  printf '{}\n' >"$PROJECT_ROOT/.config/dotnet-tools.json"
  : >"$PROJECT_ROOT/App.slnx"

  run bash -c 'cd "$1" && "$2"' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-bootstrap"

  [ "$status" -eq 0 ]
  assert_output_contains "Repository ready."

  grep -Fxq "$PROJECT_ROOT|tool restore" "$DOTNET_LOG"
  grep -Fq "restore $PROJECT_ROOT/App.slnx" "$DOTNET_LOG"
}

@test "dotnet-bootstrap refuses to choose between multiple solutions" {
  : >"$PROJECT_ROOT/App.slnx"
  : >"$PROJECT_ROOT/Samples.slnx"

  run bash -c 'cd "$1" && "$2"' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-bootstrap"

  [ "$status" -eq 2 ]
  assert_output_contains "Multiple solution files were found"
  assert_output_contains "App.slnx"
  assert_output_contains "Samples.slnx"
  [ ! -s "$DOTNET_LOG" ]
}

@test "dotnet-bootstrap accepts an explicit solution when multiple solutions exist" {
  : >"$PROJECT_ROOT/App.slnx"
  : >"$PROJECT_ROOT/Samples.slnx"

  run bash -c 'cd "$1" && "$2" Samples.slnx' _ "$PROJECT_ROOT/src/nested" "$REPO_ROOT/bin/dotnet-bootstrap"

  [ "$status" -eq 0 ]
  grep -Fq "restore $PROJECT_ROOT/Samples.slnx" "$DOTNET_LOG"
}
