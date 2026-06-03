#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  terraform-test.sh [--dir PATH ...] [--all] [--skip-fmt] [--skip-init]
                    [--skip-validate] [--skip-test] [--skip-tflint]
                    [--] [TERRAFORM_TEST_ARGS...]

Runs Terraform project checks:
  - terraform fmt -check -recursive
  - terraform init -backend=false -input=false
  - terraform validate -no-color
  - terraform test -no-color, when .tftest files are present
  - tflint, when tflint is installed

By default the current directory is tested. Use --dir more than once for
multiple root modules, or --all to discover directories containing .tf files.
Extra arguments after -- are passed to terraform test.

Terraform test files can create real infrastructure depending on their run
blocks. Review project tests and credentials before running them.
USAGE
}

discover_all=0
run_fmt=1
run_init=1
run_validate=1
run_test=1
run_tflint=1
dirs=()
test_args=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dir)
      dirs+=("${2:-}")
      shift 2
      ;;
    --all)
      discover_all=1
      shift
      ;;
    --skip-fmt)
      run_fmt=0
      shift
      ;;
    --skip-init)
      run_init=0
      shift
      ;;
    --skip-validate)
      run_validate=0
      shift
      ;;
    --skip-test)
      run_test=0
      shift
      ;;
    --skip-tflint)
      run_tflint=0
      shift
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        test_args+=("$1")
        shift
      done
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

if ! command -v terraform >/dev/null 2>&1; then
  printf 'ERROR: terraform is required\n' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

resolve_dir() {
  local dir="$1"

  if [ -z "$dir" ]; then
    printf 'ERROR: --dir requires a value\n' >&2
    exit 1
  fi

  if [ ! -d "$dir" ]; then
    printf 'ERROR: Terraform directory does not exist: %s\n' "$dir" >&2
    exit 1
  fi

  (cd "$dir" && pwd -P)
}

has_root_tf_files() {
  local dir="$1"

  find "$dir" -maxdepth 1 -type f -name '*.tf' -print -quit | grep -q .
}

has_test_files() {
  local dir="$1"

  find "$dir" -maxdepth 1 -type f \( -name '*.tftest.hcl' -o -name '*.tftest.json' \) -print -quit | grep -q . && return 0

  if [ -d "${dir}/tests" ]; then
    find "${dir}/tests" -type f \( -name '*.tftest.hcl' -o -name '*.tftest.json' \) -print -quit | grep -q . && return 0
  fi

  return 1
}

discover_dirs() {
  local root="$1"

  find "$root" \
    \( -path '*/.git' -o -path '*/.terraform' -o -path '*/.devcontainer' \) -prune \
    -o -type f -name '*.tf' -print \
    | while IFS= read -r tf_file; do
        dirname "$tf_file"
      done \
    | sort -u
}

if [ "$discover_all" -eq 1 ]; then
  if [ "${#dirs[@]}" -gt 0 ]; then
    printf 'ERROR: use either --all or --dir, not both\n' >&2
    exit 1
  fi

  while IFS= read -r discovered_dir; do
    dirs+=("$discovered_dir")
  done < <(discover_dirs "$repo_root")

  if [ "${#dirs[@]}" -eq 0 ]; then
    printf 'ERROR: no Terraform directories found under %s\n' "$repo_root" >&2
    exit 1
  fi
fi

if [ "${#dirs[@]}" -eq 0 ]; then
  dirs=("$(pwd -P)")
fi

resolved_dirs=()
for dir in "${dirs[@]}"; do
  resolved_dirs+=("$(resolve_dir "$dir")")
done

printf 'Terraform checks\n'
printf '================\n'

if [ "$run_tflint" -eq 1 ] && ! command -v tflint >/dev/null 2>&1; then
  printf '[skip] tflint is unavailable\n'
  run_tflint=0
fi

for dir in "${resolved_dirs[@]}"; do
  if ! has_root_tf_files "$dir"; then
    printf 'ERROR: no root-level .tf files found in %s\n' "$dir" >&2
    exit 1
  fi

  printf '\n%s\n' "$dir"

  if [ "$run_fmt" -eq 1 ]; then
    terraform fmt -check -recursive "$dir"
    printf '[ok] terraform fmt\n'
  fi

  if [ "$run_init" -eq 1 ]; then
    terraform -chdir="$dir" init -backend=false -input=false
    printf '[ok] terraform init\n'
  fi

  if [ "$run_validate" -eq 1 ]; then
    terraform -chdir="$dir" validate -no-color
    printf '[ok] terraform validate\n'
  fi

  if [ "$run_test" -eq 1 ]; then
    if has_test_files "$dir"; then
      if [ "${#test_args[@]}" -gt 0 ]; then
        terraform -chdir="$dir" test -no-color "${test_args[@]}"
      else
        terraform -chdir="$dir" test -no-color
      fi
      printf '[ok] terraform test\n'
    else
      printf '[skip] terraform test: no .tftest files found\n'
    fi
  fi

  if [ "$run_tflint" -eq 1 ]; then
    (cd "$dir" && tflint)
    printf '[ok] tflint\n'
  fi
done

printf '\nTerraform checks passed\n'
