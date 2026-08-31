#!/usr/bin/env bash

# Navigation
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Git
alias gs='git status --short --branch'
alias gb='git branch'
alias gba='git branch --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --graph --decorate --oneline --all'

# .NET
alias dr='dotnet restore'
alias db='dotnet build'
alias dt='dotnet test'
alias df='dotnet format'
alias dp='dotnet pack'
alias dc='dotnet clean'

# Local .NET tools
alias dtr='dotnet tool restore'
alias dtl='dotnet tool list'

# SDK/runtime diagnostics
alias dsdks='dotnet --list-sdks'
alias druntimes='dotnet --list-runtimes'
alias dinfo='dotnet --info'
