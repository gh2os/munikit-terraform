#!/usr/bin/env bash
set -euo pipefail

codex_home="${CODEX_HOME:-${HOME:-/home/vscode}/.codex}"
agents_file="${codex_home}/AGENTS.md"
defaults_file="${CODEX_DEVCONTAINER_AGENTS_DEFAULTS:-/usr/local/share/codex-devcontainer/codex-global-agents.md}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$defaults_file" ] && [ -f "${script_dir}/codex-global-agents.md" ]; then
    defaults_file="${script_dir}/codex-global-agents.md"
fi

mkdir -p "$codex_home"

if [ -s "$agents_file" ]; then
    exit 0
fi

if [ ! -f "$defaults_file" ]; then
    printf 'ERROR: Codex AGENTS.md defaults file is missing: %s\n' "$defaults_file" >&2
    exit 1
fi

umask 077
tmp_file="$(mktemp "${codex_home}/AGENTS.md.tmp.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

cp "$defaults_file" "$tmp_file"
mv "$tmp_file" "$agents_file"
trap - EXIT
