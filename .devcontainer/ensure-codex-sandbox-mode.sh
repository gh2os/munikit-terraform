#!/usr/bin/env bash
set -euo pipefail

codex_home="${CODEX_HOME:-${HOME:-/home/vscode}/.codex}"
config_file="${codex_home}/config.toml"
desired_line='sandbox_mode = "workspace-write"'

mkdir -p "${codex_home}"

if [ ! -e "${config_file}" ]; then
    umask 077
    : > "${config_file}"
fi

tmp_file="$(mktemp "${codex_home}/config.toml.tmp.XXXXXX")"
trap 'rm -f "${tmp_file}"' EXIT

awk -v desired_line="${desired_line}" '
    BEGIN {
        in_top_level = 1
        emitted = 0
    }

    in_top_level && /^[[:space:]]*sandbox_mode[[:space:]]*=/ {
        if (!emitted) {
            print desired_line
            emitted = 1
        }
        next
    }

    in_top_level && /^[[:space:]]*default_permissions[[:space:]]*=/ {
        next
    }

    in_top_level && /^[[:space:]]*\[/ {
        if (!emitted) {
            print desired_line
            emitted = 1
        }
        in_top_level = 0
    }

    {
        print
    }

    END {
        if (!emitted) {
            print desired_line
        }
    }
' "${config_file}" > "${tmp_file}"

cat "${tmp_file}" > "${config_file}"
rm -f "${tmp_file}"
trap - EXIT
