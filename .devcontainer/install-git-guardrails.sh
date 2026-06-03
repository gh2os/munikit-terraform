#!/usr/bin/env bash
set -euo pipefail

protected_branches="${CODEX_PROTECTED_BRANCHES:-main master}"
managed_marker="# Managed by Codex DevContainer git guardrails."

if ! command -v git >/dev/null 2>&1; then
  printf '[skip] git guardrails: git is unavailable\n'
  exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '[skip] git guardrails: /workspace is not a git worktree\n'
  exit 0
fi

hooks_dir="$(git rev-parse --git-path hooks)"
mkdir -p "$hooks_dir"

install_hook() {
  local hook_name="$1"
  local hook_path="${hooks_dir}/${hook_name}"
  local preserved_hook="${hook_path}.codex-preserved"
  local tmp_file

  if [ -f "$hook_path" ] && ! grep -Fq "$managed_marker" "$hook_path"; then
    if [ -e "$preserved_hook" ]; then
      local backup_hook
      backup_hook="$(mktemp "${hook_path}.codex-preserved.XXXXXX")"
      rm -f "$backup_hook"
      mv "$hook_path" "$backup_hook"
      printf '[warn] git guardrails: wrapping additional existing unmanaged hook: %s -> %s\n' "$hook_path" "$backup_hook" >&2
    else
      mv "$hook_path" "$preserved_hook"
      printf '[info] git guardrails: wrapping existing unmanaged hook: %s -> %s\n' "$hook_path" "$preserved_hook" >&2
    fi
  fi

  tmp_file="$(mktemp "${hooks_dir}/${hook_name}.tmp.XXXXXX")"
  case "$hook_name" in
    pre-commit)
      cat > "$tmp_file" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
# Managed by Codex DevContainer git guardrails.

protected_branches="${CODEX_PROTECTED_BRANCHES:-main master}"

is_protected_branch() {
  local branch="$1"
  local protected

  for protected in $protected_branches; do
    if [ "$branch" = "$protected" ]; then
      return 0
    fi
  done

  return 1
}

run_preserved_hooks() {
  local preserved_hook

  for preserved_hook in "${BASH_SOURCE[0]}".codex-preserved "${BASH_SOURCE[0]}".codex-preserved.*; do
    if [ -x "$preserved_hook" ]; then
      "$preserved_hook" "$@"
    fi
  done
}

branch="$(git branch --show-current 2>/dev/null || true)"
if [ -n "$branch" ] && is_protected_branch "$branch"; then
  printf 'ERROR: direct commits on protected branch "%s" are blocked.\n' "$branch" >&2
  printf 'Create a feature branch and use the remote GitHub/Bitbucket PR workflow.\n' >&2
  exit 1
fi

run_preserved_hooks "$@"
HOOK
      ;;
    pre-merge-commit)
      cat > "$tmp_file" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
# Managed by Codex DevContainer git guardrails.

protected_branches="${CODEX_PROTECTED_BRANCHES:-main master}"

is_protected_branch() {
  local branch="$1"
  local protected

  for protected in $protected_branches; do
    if [ "$branch" = "$protected" ]; then
      return 0
    fi
  done

  return 1
}

run_preserved_hooks() {
  local preserved_hook

  for preserved_hook in "${BASH_SOURCE[0]}".codex-preserved "${BASH_SOURCE[0]}".codex-preserved.*; do
    if [ -x "$preserved_hook" ]; then
      "$preserved_hook" "$@"
    fi
  done
}

branch="$(git branch --show-current 2>/dev/null || true)"
if [ -n "$branch" ] && is_protected_branch "$branch"; then
  printf 'ERROR: local merge commits on protected branch "%s" are blocked.\n' "$branch" >&2
  printf 'Complete final review and merge through the remote GitHub/Bitbucket PR workflow.\n' >&2
  exit 1
fi

run_preserved_hooks "$@"
HOOK
      ;;
    pre-push)
      cat > "$tmp_file" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
# Managed by Codex DevContainer git guardrails.

protected_branches="${CODEX_PROTECTED_BRANCHES:-main master}"

is_protected_branch() {
  local branch="$1"
  local protected

  for protected in $protected_branches; do
    if [ "$branch" = "$protected" ]; then
      return 0
    fi
  done

  return 1
}

run_preserved_hooks() {
  local preserved_hook

  for preserved_hook in "${BASH_SOURCE[0]}".codex-preserved "${BASH_SOURCE[0]}".codex-preserved.*; do
    if [ -x "$preserved_hook" ]; then
      "$preserved_hook" "$@"
    fi
  done
}

push_input="$(mktemp "${TMPDIR:-/tmp}/codex-pre-push.XXXXXX")"
trap 'rm -f "$push_input"' EXIT
cat > "$push_input"

while read -r local_ref local_sha remote_ref remote_sha; do
  case "$remote_ref" in
    refs/heads/*)
      remote_branch="${remote_ref#refs/heads/}"
      if is_protected_branch "$remote_branch"; then
        printf 'ERROR: direct pushes or deletes to protected branch "%s" are blocked.\n' "$remote_branch" >&2
        printf 'Push a feature branch and use the remote GitHub/Bitbucket PR workflow.\n' >&2
        exit 1
      fi
      ;;
    *)
      :
      ;;
  esac

  # Keep shellcheck happy in hooks generated for older Git versions that pass
  # an empty stdin stream.
  : "$local_ref" "$local_sha" "$remote_sha"
done < "$push_input"

run_preserved_hooks "$@" < "$push_input"
HOOK
      ;;
    *)
      printf 'ERROR: unsupported hook: %s\n' "$hook_name" >&2
      rm -f "$tmp_file"
      exit 1
      ;;
  esac

  chmod 755 "$tmp_file"
  mv "$tmp_file" "$hook_path"
}

install_hook pre-commit
install_hook pre-push
install_hook pre-merge-commit

printf '[ok] git guardrails installed for protected branches: %s\n' "$protected_branches"
