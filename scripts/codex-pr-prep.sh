#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  codex-pr-prep.sh [--remote NAME] [--base BRANCH]

Checks the current branch and prints remote-first pull request preparation
guidance for GitHub, Bitbucket, or a generic Git remote. This script never
pushes branches, creates pull requests, merges pull requests, or stores tokens.
USAGE
}

remote="origin"
base_branch=""
protected_branches="${CODEX_PROTECTED_BRANCHES:-main master}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --remote)
      remote="${2:-}"
      shift 2
      ;;
    --base)
      base_branch="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'ERROR: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$remote" ]; then
  printf 'ERROR: --remote requires a value\n' >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'ERROR: codex-pr-prep.sh must run inside a git worktree\n' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

current_branch="$(git branch --show-current)"
if [ -z "$current_branch" ]; then
  printf 'ERROR: current checkout is detached; create or switch to a feature branch first.\n' >&2
  exit 1
fi

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

if is_protected_branch "$current_branch"; then
  printf 'ERROR: current branch "%s" is protected. Create a feature branch before PR prep.\n' "$current_branch" >&2
  exit 1
fi

strip_url_userinfo() {
  local url="$1"
  local rest
  local scheme

  case "$url" in
    http://*@*|https://*@*)
      scheme="${url%%://*}://"
      rest="${url#*://}"
      printf '%s%s\n' "$scheme" "${rest#*@}"
      ;;
    *)
      printf '%s\n' "$url"
      ;;
  esac
}

remote_url="$(git remote get-url "$remote" 2>/dev/null || true)"
if [ -z "$remote_url" ]; then
  printf 'ERROR: remote not found: %s\n' "$remote" >&2
  exit 1
fi
safe_remote_url="$(strip_url_userinfo "$remote_url")"

if [ -z "$base_branch" ]; then
  origin_head="$(git symbolic-ref --quiet --short "refs/remotes/${remote}/HEAD" 2>/dev/null || true)"
  if [ -n "$origin_head" ]; then
    base_branch="${origin_head#"${remote}"/}"
  elif git show-ref --verify --quiet "refs/remotes/${remote}/main"; then
    base_branch="main"
  elif git show-ref --verify --quiet "refs/remotes/${remote}/master"; then
    base_branch="master"
  else
    base_branch="main"
  fi
fi

status_output="$(git status --short)"
provider="generic"
repo_web_url=""
repo_path=""

case "$safe_remote_url" in
  git@github.com:*|ssh://git@github.com/*|https://github.com/*|http://github.com/*)
    provider="github"
    repo_path="$safe_remote_url"
    repo_path="${repo_path#git@github.com:}"
    repo_path="${repo_path#ssh://git@github.com/}"
    repo_path="${repo_path#https://github.com/}"
    repo_path="${repo_path#http://github.com/}"
    repo_path="${repo_path%.git}"
    repo_web_url="https://github.com/${repo_path}"
    ;;
  git@bitbucket.org:*|ssh://git@bitbucket.org/*|https://bitbucket.org/*|http://bitbucket.org/*)
    provider="bitbucket"
    repo_path="$safe_remote_url"
    repo_path="${repo_path#git@bitbucket.org:}"
    repo_path="${repo_path#ssh://git@bitbucket.org/}"
    repo_path="${repo_path#https://bitbucket.org/}"
    repo_path="${repo_path#http://bitbucket.org/}"
    repo_path="${repo_path%.git}"
    repo_web_url="https://bitbucket.org/${repo_path}"
    ;;
esac

printf 'Remote-first PR preparation\n'
printf 'Repository: %s\n' "$repo_root"
printf 'Remote: %s (%s)\n' "$remote" "$safe_remote_url"
printf 'Current branch: %s\n' "$current_branch"
printf 'Base branch: %s\n' "$base_branch"

if [ -n "$status_output" ]; then
  printf '\nWorking tree has uncommitted changes:\n'
  printf '%s\n' "$status_output"
else
  printf '\nWorking tree is clean.\n'
fi

printf '\nThis script did not push, create a PR, merge, or store credentials.\n'
printf '\nNext steps:\n'
printf '1. Run the repo validation gates for this branch.\n'
printf '2. Review the final diff and commit on the feature branch when ready.\n'
printf '3. Push the feature branch yourself when ready: git push -u %s HEAD\n' "$remote"

case "$provider" in
  github)
    printf '4. Open a GitHub pull request targeting %s: %s/compare/%s...%s?expand=1\n' "$base_branch" "$repo_web_url" "$base_branch" "$current_branch"
    ;;
  bitbucket)
    printf '4. Open a Bitbucket pull request targeting %s: %s/pull-requests/new?source=%s&dest=%s\n' "$base_branch" "$repo_web_url" "$current_branch" "$base_branch"
    ;;
  *)
    printf '4. Open a pull request in the remote provider UI targeting %s.\n' "$base_branch"
    ;;
esac

printf '5. After the PR exists, run the local Codex PR review agent from this branch. Use read-only subagents by default.\n'
printf '6. Complete review, approval, and merge in the remote provider.\n'
