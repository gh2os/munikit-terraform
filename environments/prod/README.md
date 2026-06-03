# Prod Environment

Runnable root for the production environment.

Copy `terraform.tfvars.example` to `terraform.tfvars` and replace placeholders before planning or applying. Use a secured remote backend before managing production state.

## Backend

No backend block is committed for this environment. Production should use a secured remote backend from local or CI, for example:

```sh
terraform init \
  -backend-config="bucket=replace-with-state-bucket" \
  -backend-config="prefix=replace-with-state-prefix/prod"
```

For local validation without backend configuration:

```sh
terraform init -backend=false
terraform validate
```
