# Multi Instance Example

Example root for deploying several independent Munikit instances from one Terraform root.

Each key in `instances` creates a separate deployment with its own:

- Cloud SQL PostgreSQL database and `DATABASE_URL` secret.
- Media bucket, dedicated HMAC service account, and S3-compatible credential secrets.
- Runtime service account and least-privilege Cloud SQL and Secret Manager grants.
- Cloud Run service.

Copy `terraform.tfvars.example` to `terraform.tfvars` and replace placeholders before planning.
