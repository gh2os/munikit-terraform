# Single Instance Example

Example root for deploying one Munikit instance with the shared modules.

This example composes:

- `networking` for optional network scaffolding.
- `database` for one Cloud SQL PostgreSQL database and `DATABASE_URL` secret.
- `storage` for one media bucket, dedicated HMAC service account, and S3-compatible credential secrets.
- `iam` for one runtime service account with least-privilege Cloud SQL and Secret Manager grants.
- `munikit-app` for one Cloud Run service.

Copy `terraform.tfvars.example` to `terraform.tfvars` and replace placeholders before planning.
