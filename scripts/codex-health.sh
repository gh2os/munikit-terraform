#!/usr/bin/env bash
set -u

failures=0
warnings=0

pass() {
  printf '[ok] %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf '[warn] %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf '[fail] %s\n' "$1"
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "$1 is available: $($1 --version 2>&1 | head -n 1)"
  else
    fail "$1 is not available"
  fi
}

run_codex_doctor() {
  if ! command -v codex >/dev/null 2>&1; then
    warn "codex doctor skipped because codex is not installed"
    return
  fi

  local output
  output="$(codex doctor 2>&1)"
  local status=$?

  if [ "$status" -eq 0 ]; then
    pass "codex doctor passed"
  else
    warn "codex doctor reported issues"
    printf '%s\n' "$output" | sed -n '/Notes/,$p' | head -n 40
  fi
}

check_codex_config() {
  local codex_home config_file agents_file sandbox_count sandbox_line default_permissions_count default_permissions_line
  codex_home="${CODEX_HOME:-${HOME:-/home/vscode}/.codex}"
  config_file="${codex_home}/config.toml"
  agents_file="${codex_home}/AGENTS.md"

  if [ -d "$codex_home" ]; then
    pass "Codex home exists: $codex_home"
  else
    fail "Codex home is missing: $codex_home"
    return
  fi

  if [ -w "$codex_home" ]; then
    pass "Codex home is writable"
  else
    fail "Codex home is not writable: $codex_home"
  fi

  if [ -f "$config_file" ]; then
    pass "Codex config exists: $config_file"
  else
    fail "Codex config is missing: $config_file"
    return
  fi

  if [ -s "$agents_file" ]; then
    pass "Codex global instructions exist: $agents_file"
  else
    fail "Codex global instructions are missing: $agents_file"
  fi

  sandbox_count="$(
    awk '
      BEGIN { in_top_level = 1; count = 0 }
      /^[[:space:]]*\[/ { in_top_level = 0 }
      in_top_level && /^[[:space:]]*sandbox_mode[[:space:]]*=/ { count++ }
      END { print count }
    ' "$config_file"
  )"
  sandbox_line="$(
    awk '
      BEGIN { in_top_level = 1 }
      /^[[:space:]]*\[/ { in_top_level = 0 }
      in_top_level && /^[[:space:]]*sandbox_mode[[:space:]]*=/ { print; exit }
    ' "$config_file"
  )"

  if [ "$sandbox_count" -eq 1 ] && [ "$sandbox_line" = 'sandbox_mode = "workspace-write"' ]; then
    pass 'Codex sandbox_mode is workspace-write'
  else
    fail 'Codex config must contain exactly one top-level sandbox_mode = "workspace-write"'
    printf '  found %s top-level sandbox_mode entr%s\n' "$sandbox_count" "$([ "$sandbox_count" -eq 1 ] && printf 'y' || printf 'ies')"
    if [ -n "$sandbox_line" ]; then
      printf '  first entry: %s\n' "$sandbox_line"
    fi
  fi

  default_permissions_count="$(
    awk '
      BEGIN { in_top_level = 1; count = 0 }
      /^[[:space:]]*\[/ { in_top_level = 0 }
      in_top_level && /^[[:space:]]*default_permissions[[:space:]]*=/ { count++ }
      END { print count }
    ' "$config_file"
  )"
  default_permissions_line="$(
    awk '
      BEGIN { in_top_level = 1 }
      /^[[:space:]]*\[/ { in_top_level = 0 }
      in_top_level && /^[[:space:]]*default_permissions[[:space:]]*=/ { print; exit }
    ' "$config_file"
  )"

  if [ "$default_permissions_count" -eq 0 ]; then
    pass "Codex config has no top-level default_permissions conflict"
  else
    fail "Codex config must not combine top-level default_permissions with sandbox_mode"
    printf '  found %s top-level default_permissions entr%s\n' "$default_permissions_count" "$([ "$default_permissions_count" -eq 1 ] && printf 'y' || printf 'ies')"
    printf '  first entry: %s\n' "$default_permissions_line"
  fi

  if [ -d /workspace ] && [ "$codex_home" = "/home/vscode/.codex" ]; then
    if command -v mountpoint >/dev/null 2>&1; then
      if mountpoint -q "$codex_home"; then
        pass "/home/vscode/.codex is mounted"
      else
        fail "/home/vscode/.codex is not a mount point; Codex state may not persist"
      fi
    else
      warn "mountpoint is unavailable; skipping Codex volume mount check"
    fi
  fi
}

check_vscode_codex_extension() {
  if ! command -v code >/dev/null 2>&1; then
    warn "VS Code CLI is unavailable; skipping Codex extension check"
    return
  fi

  local extensions
  if extensions="$(code --list-extensions 2>/dev/null)"; then
    if printf '%s\n' "$extensions" | grep -Fxq "openai.chatgpt"; then
      pass "Codex VS Code extension is installed: openai.chatgpt"
    else
      fail "Codex VS Code extension is not installed: openai.chatgpt"
    fi
  else
    warn "VS Code CLI could not list extensions; check the Extensions panel for openai.chatgpt"
  fi
}

check_shell_history() {
  local history_home bashrc zshrc
  history_home="${SHELL_HISTORY_HOME:-${HOME:-/home/vscode}/.shell-history}"
  bashrc="${HOME:-/home/vscode}/.bashrc"
  zshrc="${HOME:-/home/vscode}/.zshrc"

  if [ -d "$history_home" ]; then
    pass "Shell history directory exists: $history_home"
  else
    fail "Shell history directory is missing: $history_home"
    return
  fi

  if [ -w "$history_home" ]; then
    pass "Shell history directory is writable"
  else
    fail "Shell history directory is not writable: $history_home"
  fi

  if [ -f "$history_home/bash_history" ]; then
    pass "Bash history file exists"
  else
    fail "Bash history file is missing: $history_home/bash_history"
  fi

  if [ -f "$history_home/zsh_history" ]; then
    pass "Zsh history file exists"
  else
    fail "Zsh history file is missing: $history_home/zsh_history"
  fi

  if [ -f "$bashrc" ] && grep -Fxq 'export HISTFILE="${SHELL_HISTORY_HOME:-$HOME/.shell-history}/bash_history"' "$bashrc"; then
    pass "Bash is configured to use persisted history"
  else
    fail "Bash history is not configured in $bashrc"
  fi

  if [ -f "$zshrc" ] && grep -Fxq 'export HISTFILE="${SHELL_HISTORY_HOME:-$HOME/.shell-history}/zsh_history"' "$zshrc"; then
    pass "Zsh is configured to use persisted history"
  else
    fail "Zsh history is not configured in $zshrc"
  fi

  if [ -d /workspace ] && [ "$history_home" = "/home/vscode/.shell-history" ]; then
    if command -v mountpoint >/dev/null 2>&1; then
      if mountpoint -q "$history_home"; then
        pass "/home/vscode/.shell-history is mounted"
      else
        fail "/home/vscode/.shell-history is not a mount point; shell history may not persist"
      fi
    else
      warn "mountpoint is unavailable; skipping shell history volume mount check"
    fi
  fi
}

check_git_state() {
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    fail "current directory is not inside a Git repository"
    return
  fi

  local root branch status
  root="$(git rev-parse --show-toplevel)"
  branch="$(git branch --show-current)"
  status="$(git status --short)"

  pass "Git repository: $root"
  pass "Git branch: ${branch:-detached HEAD}"

  if [ -z "$status" ]; then
    pass "Git working tree is clean"
  else
    warn "Git working tree has uncommitted changes"
    printf '%s\n' "$status"
  fi

  if git remote get-url origin >/dev/null 2>&1; then
    pass "origin remote: $(git remote get-url origin)"
  else
    warn "origin remote is not configured"
  fi
}

check_workspaces() {
  if [ -d /workspace ]; then
    pass "/workspace is mounted"
    if git_root="$(git -C /workspace rev-parse --show-toplevel 2>/dev/null)"; then
      pass "Workspace Git root: $git_root"
    else
      warn "/workspace is not a Git repository"
    fi
  else
    fail "/workspace is not mounted"
  fi

  if [ -d /workspaces ]; then
    warn "/workspaces exists; secure profile should mount only the current worktree at /workspace"
  fi
}

check_terminal() {
  if [ "${TERM:-}" = "xterm-256color" ]; then
    pass "TERM is xterm-256color"
  else
    warn "TERM is '${TERM:-unset}', expected xterm-256color"
  fi

  if [ "${COLORTERM:-}" = "truecolor" ]; then
    pass "COLORTERM is truecolor"
  else
    warn "COLORTERM is '${COLORTERM:-unset}', expected truecolor"
  fi
}

check_codex_linux_sandbox() {
  if [ "$(uname -s)" != "Linux" ]; then
    warn "Codex Linux sandbox check skipped outside Linux"
    return
  fi

  if command -v bwrap >/dev/null 2>&1; then
    pass "bubblewrap is available: $(command -v bwrap)"
  else
    fail "bubblewrap is not available"
    return
  fi

  if [ -u "$(command -v bwrap)" ]; then
    pass "bubblewrap has setuid bit for nested sandboxing"
  else
    warn "bubblewrap does not have setuid bit; sandbox may rely on unprivileged user namespaces"
  fi

  if ! command -v codex >/dev/null 2>&1; then
    warn "Codex sandbox smoke test skipped because codex is not installed"
    return
  fi

  local output
  output="$(codex sandbox true 2>&1)"
  local status=$?
  if [ "$status" -eq 0 ]; then
    pass "Codex Linux sandbox smoke test passed"
  else
    fail "Codex Linux sandbox smoke test failed"
    printf '%s\n' "$output" | head -n 20
  fi
}

check_network_controls() {
  if [ "${CODEX_ENABLE_FIREWALL:-0}" = "1" ]; then
    pass "Codex network firewall is requested for the main DevContainer path"
    warn "Docker-in-Docker and BuildKit egress require separate validation"
  else
    warn "Codex network firewall is disabled for the main DevContainer path"
    warn "Docker-in-Docker and BuildKit egress are not controlled by this firewall"
  fi
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    fail "docker CLI is not available"
    return
  fi

  pass "docker CLI is available: $(docker --version 2>&1)"

  if docker compose version >/dev/null 2>&1; then
    pass "docker compose is available: $(docker compose version 2>&1)"
  else
    warn "docker compose is not available"
  fi

  if [ -S /var/run/docker.sock ]; then
    pass "Docker daemon socket exists at /var/run/docker.sock"
  else
    fail "Docker socket is not available at /var/run/docker.sock"
    return
  fi

  if [ -S /var/run/docker-host.sock ]; then
    fail "Host Docker socket appears to be mounted at /var/run/docker-host.sock"
  else
    pass "Host Docker socket is not mounted at /var/run/docker-host.sock"
  fi

  if docker version >/dev/null 2>&1; then
    pass "Docker daemon is reachable"
  else
    fail "Docker daemon is not reachable from inside the container"
  fi
}

check_ssh_agent() {
  if ! command -v ssh-add >/dev/null 2>&1; then
    fail "ssh-add is not available"
    return
  fi

  if [ -z "${SSH_AUTH_SOCK:-}" ]; then
    fail "SSH_AUTH_SOCK is not set"
    return
  fi

  if [ -S "$SSH_AUTH_SOCK" ]; then
    pass "SSH agent socket exists at $SSH_AUTH_SOCK"
  else
    fail "SSH_AUTH_SOCK points to a missing socket: $SSH_AUTH_SOCK"
    return
  fi

  if ssh-add -l >/dev/null 2>&1; then
    pass "SSH agent has at least one identity loaded"
  else
    warn "SSH agent is reachable but has no loaded identities"
  fi

  if git remote get-url origin >/dev/null 2>&1; then
    local remote
    remote="$(git remote get-url origin)"
    if printf '%s\n' "$remote" | grep -Eq '^(git@|ssh://)'; then
      if command -v timeout >/dev/null 2>&1; then
        if timeout 15 git ls-remote --exit-code origin HEAD >/dev/null 2>&1; then
          pass "origin is reachable over SSH"
        else
          warn "origin SSH check failed; verify host SSH aliases and loaded keys"
        fi
      else
        warn "timeout is unavailable; skipping origin SSH reachability check"
      fi
    else
      warn "origin is not an SSH remote; skipping SSH reachability check"
    fi
  fi
}

printf 'Codex environment health\n'
printf '========================\n'

check_command codex
check_command rg
check_git_state
check_workspaces
check_terminal
check_codex_config
check_codex_linux_sandbox
check_network_controls
check_vscode_codex_extension
check_shell_history
run_codex_doctor
check_docker
check_ssh_agent

printf '\nSummary: %s failure(s), %s warning(s)\n' "$failures" "$warnings"

if [ "$failures" -gt 0 ]; then
  exit 1
fi

exit 0
