# storage Module

Reusable module for media storage.

This module creates:

- A Cloud Storage media bucket.
- Optional public object read access for public municipal media.
- A dedicated service account and HMAC key for S3-compatible Payload storage access.
- Secret Manager secrets for `S3_ACCESS_KEY_ID` and `S3_SECRET_ACCESS_KEY`.

HMAC secret values are written to Secret Manager and Terraform state. Use a secured remote backend for real environments.
