#!/usr/bin/env bash

dotnet-sdk() {
  if [[ -f global.json ]]; then
    echo "Repository SDK configuration:"
    cat global.json
    echo
  else
    echo "global.json: not found"
    echo
  fi

  if command -v dotnet >/dev/null 2>&1; then
    echo "Resolved SDK:"
    dotnet --version
  else
    echo ".NET SDK not found"
    return 1
  fi
}

dotnet-tools() {
  if [[ ! -f .config/dotnet-tools.json ]]; then
    echo "No local .NET tool manifest found."
    return 0
  fi

  dotnet tool list
}

dotnet-solutions() {
  find . -maxdepth 1 \( -name "*.sln" -o -name "*.slnx" \) -print
}
