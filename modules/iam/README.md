# iam Module

Reusable module for least-privilege runtime IAM.

This module creates the user-managed runtime service account and grants only the requested permissions:

- `roles/cloudsql.client` at the project level when Cloud SQL access is needed.
- `roles/secretmanager.secretAccessor` on specific secrets.
- Optional bucket-scoped object access on a specific media bucket when requested.

For the default Payload S3-compatible media flow, leave runtime media bucket access disabled and use the dedicated HMAC service account from the `storage` module.
