# munikit-app Module

Reusable module for a containerized Payload/Next.js application on Cloud Run.

This module creates:

- A Secret Manager secret for `PAYLOAD_SECRET`.
- A Cloud Run v2 service configured for port `3000` by default.
- Secret-backed runtime variables for `DATABASE_URL`, `PAYLOAD_SECRET`, and optional S3 credentials.
- Optional public `roles/run.invoker`.
- An optional Artifact Registry Docker repository.

The runtime service account and cross-resource IAM grants are intentionally owned by the `iam` module to keep permission boundaries explicit.
