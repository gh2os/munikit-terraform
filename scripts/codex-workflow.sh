#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  codex-workflow.sh [--project terraform|cdk|base] [--skip-health]
                    [--skip-project] [--skip-sandbox] [--skip-docker]
                    [PROJECT_CHECK_ARGS...]

Runs the standard Codex project loop:
  - scripts/codex-health.sh
  - scripts/terraform-test.sh or scripts/cdk-test.sh, when present
  - codex sandbox true
  - docker version

Examples:
  scripts/codex-workflow.sh
  scripts/codex-workflow.sh --all
  scripts/codex-workflow.sh --dir envs/dev --dir envs/prod
  scripts/codex-workflow.sh --skip-health --all -- -verbose
USAGE
}

run_health=1
run_project=1
run_sandbox=1
run_docker=1
project_kind=""
project_args=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-health)
      run_health=0
      shift
      ;;
    --skip-project|--skip-terraform|--skip-cdk)
      run_project=0
      shift
      ;;
    --project)
      project_kind="${2:-}"
      case "$project_kind" in
        terraform|cdk|base) ;;
        *)
          printf 'ERROR: --project must be terraform, cdk, or base\n' >&2
          exit 1
          ;;
      esac
      shift 2
      ;;
    --skip-sandbox)
      run_sandbox=0
      shift
      ;;
    --skip-docker)
      run_docker=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      project_args+=("--")
      shift
      while [ "$#" -gt 0 ]; do
        project_args+=("$1")
        shift
      done
      ;;
    *)
      project_args+=("$1")
      shift
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
project_check_name=""
project_check_script=""

run_step() {
  local name="$1"
  shift

  printf '\n==> %s\n' "$name"
  "$@"
}

cd "$repo_root"

template_project_kind() {
  local lock_file="${repo_root}/.devcontainer/template.lock.json"

  if [ ! -f "$lock_file" ]; then
    return
  fi

  if command -v jq >/dev/null 2>&1; then
    jq -r '.template // empty' "$lock_file" 2>/dev/null || true
  else
    sed -n 's/.*"template"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$lock_file" | head -n 1
  fi
}

select_project_check() {
  local has_terraform=0
  local has_cdk=0

  [ -x "${script_dir}/terraform-test.sh" ] && has_terraform=1
  [ -x "${script_dir}/cdk-test.sh" ] && has_cdk=1

  if [ -z "$project_kind" ]; then
    project_kind="$(template_project_kind)"
  fi

  case "$project_kind" in
    terraform)
      if [ "$has_terraform" -ne 1 ]; then
        printf 'ERROR: --project terraform requested but scripts/terraform-test.sh is missing\n' >&2
        exit 1
      fi
      project_check_name="Terraform project checks"
      project_check_script="${script_dir}/terraform-test.sh"
      ;;
    cdk)
      if [ "$has_cdk" -ne 1 ]; then
        printf 'ERROR: --project cdk requested but scripts/cdk-test.sh is missing\n' >&2
        exit 1
      fi
      project_check_name="CDK project checks"
      project_check_script="${script_dir}/cdk-test.sh"
      ;;
    base)
      project_check_name=""
      project_check_script=""
      ;;
    "")
      if [ "$has_terraform" -eq 1 ] && [ "$has_cdk" -eq 1 ]; then
        printf 'ERROR: both terraform-test.sh and cdk-test.sh exist; pass --project terraform or --project cdk\n' >&2
        exit 1
      elif [ "$has_terraform" -eq 1 ]; then
        project_check_name="Terraform project checks"
        project_check_script="${script_dir}/terraform-test.sh"
      elif [ "$has_cdk" -eq 1 ]; then
        project_check_name="CDK project checks"
        project_check_script="${script_dir}/cdk-test.sh"
      fi
      ;;
    *)
      printf 'ERROR: unsupported template project type in .devcontainer/template.lock.json: %s\n' "$project_kind" >&2
      exit 1
      ;;
  esac
}

select_project_check

if [ "$run_health" -eq 1 ]; then
  run_step "Codex environment health" "${script_dir}/codex-health.sh"
fi

if [ "$run_project" -eq 1 ]; then
  if [ -n "$project_check_script" ]; then
    if [ "${#project_args[@]}" -gt 0 ]; then
      run_step "$project_check_name" "$project_check_script" "${project_args[@]}"
    else
      run_step "$project_check_name" "$project_check_script"
    fi
  else
    printf '\n[skip] project checks: no terraform-test.sh or cdk-test.sh found\n'
  fi
fi

if [ "$run_sandbox" -eq 1 ]; then
  if ! command -v codex >/dev/null 2>&1; then
    printf 'ERROR: codex is required for sandbox validation\n' >&2
    exit 1
  fi
  run_step "Codex sandbox smoke test" codex sandbox true
fi

if [ "$run_docker" -eq 1 ]; then
  if ! command -v docker >/dev/null 2>&1; then
    printf 'ERROR: docker is required for Docker validation\n' >&2
    exit 1
  fi
  run_step "Docker daemon check" docker version
fi

printf '\nCodex workflow checks passed\n'
