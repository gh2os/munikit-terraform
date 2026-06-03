# Codex Guidance

## Repo Purpose

This repo contains reusable GCP Terraform for Munikit and future apps. Build modules and environment roots that can be shared across products without baking in Munikit-only assumptions.

## Expected Structure

- `modules/`: reusable Terraform modules with clear inputs, outputs, and validation.
- `environments/`: runnable environment roots for real deployments.
- `examples/`: small runnable examples for modules or common deployment shapes.
- `README.md`: repo overview, usage, deployment workflow, and assumptions.

## Terraform Conventions

- Run `terraform fmt -recursive` before handing off changes.
- Validate every runnable root after initialization.
- Do not hardcode GCP project IDs, regions, app names, domains, or environment names.
- Use variables, outputs, and variable validation for configurable behavior.
- Prefer explicit, least-privilege IAM bindings over broad roles.
- Keep defaults low-cost and appropriate for development unless production intent is explicit.
- Keep modules reusable; pass product-specific names and labels from environment roots.
- Document non-obvious provider, backend, API, and quota assumptions near the relevant code.

## Safety Rules

- Never run `terraform apply` or `terraform destroy` unless the user explicitly asks for it.
- Never commit secrets, credentials, private keys, `.tfvars` with real values, or generated state files.
- Document assumptions instead of silently encoding them.
- Do not edit `munikit-app-code` unless the user explicitly asks for changes there.

## Verification Commands

For each runnable Terraform root:

```sh
terraform init -backend=false
terraform validate
```

For the whole repo:

```sh
terraform fmt -recursive
```

## Documentation Expectations

- Maintain `README.md` with purpose, structure, prerequisites, and deployment steps.
- Include example `.tfvars` files or snippets with placeholder values only.
- Document module outputs and how downstream code should consume them.
- Include assumptions for GCP APIs, IAM permissions, billing, regions, domains, and environments.
- Show verification commands and any expected ordering between modules or environments.


<!-- BEGIN MANAGED DEVCONTAINER TEMPLATE INSTRUCTIONS -->
# Codex Instructions

These instructions apply to this Terraform infrastructure repository.

## Repository Context

- This repo uses the reusable Terraform DevContainer template.
- Default Terraform root: `.`.
- For multi-root repos, keep this section updated with explicit root modules
  and prefer `scripts/terraform-test.sh --dir ROOT` over broad discovery.
- Project `.devcontainer` files are real copied files. Runtime behavior must not
  depend on the template repo being mounted.
- Template refreshes update the managed DevContainer instructions block in this
  file while preserving project-specific root modules and safety notes outside
  that block.

## Codex Workflow

- Start by checking `git status --short` and the current branch.
- Treat uncommitted changes as user work unless you made them in the current
  task.
- Write commit messages in lowercase unless preserving an acronym or matching
  an established syntax style.
- Work on feature branches. Do not commit, merge, or push directly to `main` or
  `master`.
- Final pull request creation, approval, and merge should happen in the remote
  GitHub or Bitbucket repository, not by locally merging protected branches.
- After a PR is submitted, run local read-only Codex PR review with subagents by default.
- Do not enable Codex cloud review, GitHub Actions, or automatic PR reviews
  unless explicitly requested.
- Before Terraform-impacting edits, summarize the intended change and the root
  modules affected.
- Use read-only review prompts before implementing risky infrastructure,
  backend, state, IAM, networking, or production-impacting changes.
- Use one Git worktree, one DevContainer, and one Codex session per task.

## Validation

Run the narrowest useful validation before handing off.

Preferred full local loop:

```bash
scripts/codex-workflow.sh
```

For multi-root repos, prefer explicit roots:

```bash
scripts/codex-workflow.sh --dir envs/dev --dir envs/prod
```

Useful individual checks:

```bash
scripts/codex-health.sh
scripts/codex-pr-prep.sh
scripts/terraform-test.sh
scripts/terraform-test.sh --all
codex sandbox true
docker version
```

`scripts/terraform-test.sh` runs `terraform init -backend=false`, so the default
validation path should not attach to remote state.

## Cloud Safety

- Do not run `terraform apply`, `terraform destroy`, `terraform import`,
  `terraform state`, `terraform taint`, or `terraform untaint` unless the user
  explicitly asks for that exact action.
- Ask before running `terraform plan` against live credentials, remote state, or
  production workspaces unless the user already requested it.
- Do not change Terraform backend configuration, workspaces, state files, or
  provider authentication flows unless the task explicitly requires it.
- Do not commit `.tfstate`, `.tfstate.backup`, private keys, tokens, AWS
  credentials, client env files, or generated secret material.

## DevContainer Security

- Keep Codex running with `sandbox_mode = "workspace-write"`.
- Keep Docker-in-Docker as the default Docker path. Do not mount the host Docker
  socket in the default profile.
- Keep SSH private keys on the host and use the forwarded SSH agent.
- Keep `CODEX_ENABLE_FIREWALL=0` by default. For sensitive clients, update
  `.devcontainer/codex-allowed-domains.txt`, rebuild the DevContainer, and
  separately validate Terraform provider installs plus Docker-in-Docker or
  BuildKit egress.

<!-- END MANAGED DEVCONTAINER TEMPLATE INSTRUCTIONS -->
