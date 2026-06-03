# Dev Environment

Runnable root for the development environment.

Copy `terraform.tfvars.example` to `terraform.tfvars` and replace placeholders before planning or applying.

## Backend

No backend block is committed for this environment. For real deployments, initialize with a secured remote backend from local or CI, for example:

```sh
terraform init \
  -backend-config="bucket=replace-with-state-bucket" \
  -backend-config="prefix=replace-with-state-prefix/dev"
```

For local validation without backend configuration:

```sh
terraform init -backend=false
terraform validate
```
