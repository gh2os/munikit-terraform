# Munikit GCP Terraform Infrastructure Plan

## Summary

- Munikit is a **Payload CMS 3 + Next.js 16** app running on **Node 22**, backed by **PostgreSQL**, with media uploads through Payload’s S3-compatible storage adapter.
- Recommended GCP architecture:
  - **Cloud Run** for the containerized Next/Payload app.
  - **Cloud SQL for PostgreSQL 16** for the Payload database.
  - **Cloud Storage** using S3 interoperability/HMAC credentials for Payload media.
  - **Secret Manager** for `DATABASE_URL`, `PAYLOAD_SECRET`, and S3/HMAC credentials.
  - **Artifact Registry** for container images, referenced by Terraform via `container_image`.
- Cloud Run is a better fit than GKE or Compute Engine because the app is HTTP-only, server-rendered, container-ready, and has no discovered background workers. Firebase Hosting alone is not enough because the app has SSR, Payload admin, REST/GraphQL APIs, and DB access.

## Key Changes

- Create Terraform in `/Users/g/work/personal/munikit/munikit-terraform` with:
  - `modules/munikit-app`
  - `modules/networking`
  - `modules/database`
  - `modules/storage`
  - `modules/iam`
  - `environments/dev`, `environments/staging`, `environments/prod`
  - `examples/single-instance`, `examples/multi-instance`
  - top-level `README.md`
- Use reusable variables for `project_id`, `region`, `app_name`, `environment`, `instance_name`, `container_image`, labels, Cloud Run sizing, DB tier, DB deletion protection, bucket location, and optional env vars.
- Default runtime settings:
  - Cloud Run port `3000`
  - min instances `0`
  - low default max instances
  - user-managed runtime service account
  - public invoker enabled by variable for municipal public sites
  - Cloud SQL mounted through Cloud Run’s Cloud SQL volume using Unix socket path
- Store secrets as Secret Manager secrets and grant the Cloud Run service account `roles/secretmanager.secretAccessor` only on those secrets.
- Grant least-privilege IAM:
  - Cloud SQL Client on the runtime service account
  - bucket-scoped object access for media storage
  - no broad project Editor/Owner bindings
- Add example `.tfvars` files for dev, staging, prod, single-instance, and multi-instance deployments.

## Terraform Interfaces

- Main environment variables:
  - `project_id`
  - `region`
  - `app_name`
  - `environment`
  - `instance_name`
  - `container_image`
  - `labels`
  - `allow_unauthenticated`
  - `cloud_run_cpu`, `cloud_run_memory`, `min_instances`, `max_instances`, `concurrency`
  - `database_version`, `database_tier`, `database_disk_size_gb`, `database_deletion_protection`, `database_backup_enabled`
  - `bucket_location`, `public_media`
  - `extra_env_vars`, including optional `ENABLE_SHERIFF_SALES` and `LATAHCOUNTY_THEME`
- Important outputs:
  - Cloud Run service name and URL
  - runtime service account email
  - Cloud SQL instance name and connection name
  - database name and database user
  - Secret Manager secret IDs for `DATABASE_URL`, `PAYLOAD_SECRET`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`
  - media bucket name and URL
  - Artifact Registry repository URL, if created
- The generated `DATABASE_URL` will use the Cloud SQL Unix socket form:
  - `postgresql://<user>:<password>@localhost:5432/<db>?host=/cloudsql/<connection_name>`

## App-Side Deployment Notes

- The existing Dockerfile expects `.next/standalone`, but `next.config.ts` does not currently set `output: 'standalone'`; add that before relying on the Dockerfile for Cloud Run images.
- If Payload’s S3 adapter emits remote GCS URLs, add the chosen GCS/media host to `next.config.ts` image `remotePatterns`, since the app currently only allows local `/api/media/file/**`.
- Terraform will not run Payload migrations. The README will document running `pnpm payload migrate` from local/CI using Cloud SQL Auth Proxy or another controlled migration path before first production deploy.
- No Terraform will be added for queues, Redis, Cloud Scheduler, or email because the repo does not show runtime requirements for those yet.

## Test Plan

- Run `terraform fmt -recursive`.
- Run `terraform init -backend=false` and `terraform validate` in:
  - `environments/dev`
  - `environments/staging`
  - `environments/prod`
  - `examples/single-instance`
  - `examples/multi-instance`
- Validate module examples compile without hardcoded project IDs, regions, domains, app names, or environment names.
- After apply, smoke-test:
  - Cloud Run service URL returns the public site.
  - `/admin` loads.
  - app can connect to Cloud SQL.
  - media upload writes to the configured bucket.
  - runtime service account has no broad project-level permissions.

## Assumptions And References

- Default deployment target is GCP-managed/serverless with low cost defaults; private VPC database networking will be configurable but not the default because Cloud Run plus Cloud SQL connector avoids extra networking resources.
- Media is public by default because the public site renders uploaded images and documents.
- Secrets generated by Terraform will appear in Terraform state; README will recommend a secured remote GCS backend for real environments.
- GCP references used:
  - [Cloud Run container contract](https://docs.cloud.google.com/run/docs/container-contract)
  - [Cloud Run environment variables and Secret Manager guidance](https://docs.cloud.google.com/run/docs/configuring/services/environment-variables)
  - [Cloud Run secrets configuration](https://docs.cloud.google.com/run/docs/configuring/services/secrets)
  - [Cloud Run to Cloud SQL for PostgreSQL](https://docs.cloud.google.com/sql/docs/postgres/connect-run)
  - [Cloud Storage S3 interoperability](https://docs.cloud.google.com/storage/docs/interoperability)
