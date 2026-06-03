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
