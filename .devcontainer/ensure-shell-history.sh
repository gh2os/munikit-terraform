#!/usr/bin/env bash
set -euo pipefail

history_home="${SHELL_HISTORY_HOME:-${HOME:-/home/vscode}/.shell-history}"
bash_history="${history_home}/bash_history"
zsh_history="${history_home}/zsh_history"
home_dir="${HOME:-/home/vscode}"
bashrc="${home_dir}/.bashrc"
zshrc="${home_dir}/.zshrc"

mkdir -p "${home_dir}"
mkdir -p "${history_home}"
touch "${bash_history}" "${zsh_history}"
chmod 700 "${history_home}"
chmod 600 "${bash_history}" "${zsh_history}"

ensure_line() {
  local file="$1"
  local line="$2"

  touch "${file}"
  if ! grep -Fxq "${line}" "${file}"; then
    printf '%s\n' "${line}" >> "${file}"
  fi
}

ensure_line "${bashrc}" 'export HISTFILE="${SHELL_HISTORY_HOME:-$HOME/.shell-history}/bash_history"'
ensure_line "${bashrc}" 'export HISTSIZE=50000'
ensure_line "${bashrc}" 'export HISTFILESIZE=100000'
ensure_line "${bashrc}" 'shopt -s histappend'
ensure_line "${bashrc}" 'PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"'

ensure_line "${zshrc}" 'export HISTFILE="${SHELL_HISTORY_HOME:-$HOME/.shell-history}/zsh_history"'
ensure_line "${zshrc}" 'export HISTSIZE=50000'
ensure_line "${zshrc}" 'export SAVEHIST=100000'
ensure_line "${zshrc}" 'setopt APPEND_HISTORY'
ensure_line "${zshrc}" 'setopt INC_APPEND_HISTORY'
ensure_line "${zshrc}" 'setopt SHARE_HISTORY'
