# Munikit Terraform

Reusable GCP Terraform for Munikit and future Payload/Next.js applications.

This repository defines a low-cost, serverless-first GCP stack for running a containerized Payload CMS 3 and Next.js 16 app. The modules are intentionally reusable: project IDs, regions, app names, instance names, domains, and environment names are all passed in by variables rather than hardcoded.

## App Infrastructure Findings

The Munikit app is a Payload CMS 3 and Next.js 16 application running on Node 22. It uses PostgreSQL through Payload's Postgres adapter and stores uploaded media through Payload's S3-compatible storage adapter when S3 settings are provided.

The app is a good fit for Cloud Run because it is HTTP-oriented, container-ready, server-rendered, and has no discovered queue workers, Redis dependency, scheduler, or separate background process requirement. Firebase Hosting alone is not enough because the app includes SSR, the Payload admin UI, REST/GraphQL API routes, and direct database access.

Runtime assumptions captured by this Terraform:

- The container listens on port `3000`.
- Runtime image builds happen outside Terraform and are passed in as `container_image`.
- `DATABASE_URL` is provided from Secret Manager.
- `PAYLOAD_SECRET` is generated and stored in Secret Manager unless explicitly supplied to the app module.
- Media storage uses `S3_BUCKET`, `S3_ENDPOINT`, `S3_REGION`, `S3_ACCESS_KEY_ID`, and `S3_SECRET_ACCESS_KEY`.
- Optional product-specific flags, such as `ENABLE_SHERIFF_SALES`, are passed through `extra_env_vars`.

## Recommended GCP Architecture

- Cloud Run for the containerized Next/Payload app.
- Cloud SQL for PostgreSQL 16 for the Payload database.
- Cloud Storage for media, with S3 interoperability/HMAC credentials for Payload's S3-compatible storage adapter.
- Secret Manager for `DATABASE_URL`, `PAYLOAD_SECRET`, and S3/HMAC credentials.
- Artifact Registry for container images. Terraform can optionally create a repository, but images are built and pushed outside Terraform.
- Optional VPC and Serverless VPC Access only when private networking is needed. The default Cloud Run to Cloud SQL path uses the Cloud SQL connector and avoids always-on networking cost.

IAM is intentionally narrow:

- A user-managed runtime service account is created per app instance.
- The runtime service account receives `roles/cloudsql.client`.
- Secret access is granted only on the specific secrets needed by that instance.
- Media writes use a dedicated HMAC service account with bucket-scoped object access.
- Direct media bucket access for the runtime service account is opt-in with `grant_runtime_bucket_access`.
- No module grants broad project Editor or Owner roles.

Generated names include `app_name`, `environment`, and `instance_name` where provider limits allow. When a provider limit requires shortening, roots and modules add a deterministic hash suffix rather than plain truncation to avoid long-name collisions. Serverless VPC Access connector names are especially short, so the networking module uses a compact hashed default. Default media bucket names use a deterministic `media-<sha1>` value because Cloud Storage bucket names are globally shared and reject some otherwise valid app or project names, including `goog` and `google`-like strings.

## Repo Structure

- `modules/munikit-app`: Cloud Run service, Payload secret, secret-backed runtime env vars, Cloud SQL mount, public invoker option, and optional Artifact Registry repository.
- `modules/networking`: optional VPC network and optional Serverless VPC Access connector. Creates no resources by default.
- `modules/database`: Cloud SQL PostgreSQL instance, app database, app database user, generated database password, and `DATABASE_URL` Secret Manager secret.
- `modules/storage`: Cloud Storage media bucket, optional public object read, HMAC service account/key with bucket-scoped object access, and S3 credential Secret Manager secrets.
- `modules/iam`: runtime service account and least-privilege IAM grants for Cloud SQL, Secret Manager, and optional direct media bucket access.
- `environments/dev`: runnable root for a low-cost development deployment.
- `environments/staging`: runnable root for staging.
- `environments/prod`: runnable root for production with safer defaults.
- `examples/single-instance`: example root for one Munikit deployment.
- `examples/multi-instance`: example root for several independent Munikit deployments from one root.

## Prerequisites

- Terraform `>= 1.6.0`.
- A GCP project with billing enabled.
- GCP authentication configured for Terraform, for example Application Default Credentials or CI workload identity.
- Permissions to manage the resources used by the selected root, including Cloud Run, Cloud SQL, Cloud Storage, Secret Manager, IAM, and optionally Artifact Registry and VPC Access.
- Required APIs enabled in the target project:
  - Cloud Run API
  - Cloud SQL Admin API
  - Cloud Storage API
  - Secret Manager API
  - IAM Service Account Credentials API
  - Artifact Registry API, if creating or using Artifact Registry
  - Serverless VPC Access API and Compute Engine API, if enabling networking resources
- A container image already built and pushed to a registry Cloud Run can pull from.
- A remote Terraform backend for real environments. Backend config is documented in each environment README; no real backend block or state bucket is committed here.

## How To Deploy A New Instance

These steps describe the intended workflow. Do not run `terraform apply` until project, IAM, backend, image, and tfvars have been reviewed.

1. Choose a root:
   - Use `environments/dev`, `environments/staging`, or `environments/prod` for real lifecycle environments.
   - Use `examples/single-instance` to learn the one-instance wiring.
   - Use `examples/multi-instance` to model multiple independent Munikit deployments from one root.

2. Copy the placeholder tfvars file:

   ```sh
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Replace all placeholder values:
   - `project_id`
   - `region`
   - `app_name`
   - `environment`
   - `instance_name`
   - `container_image`
   - labels
   - any optional `extra_env_vars`

4. Configure a secure backend for real deployments. Each environment README shows a placeholder backend command. For local validation only, use:

   ```sh
   terraform init -backend=false
   terraform validate
   ```

5. Build and push the app image outside Terraform.

6. Review the plan:

   ```sh
   terraform plan -var-file=terraform.tfvars
   ```

7. Apply only after review and explicit approval:

   ```sh
   terraform apply -var-file=terraform.tfvars
   ```

8. Run Payload migrations through the controlled migration flow described below.

9. Smoke-test the deployment:
   - Cloud Run service URL loads the public site.
   - `/admin` loads.
   - The app connects to Cloud SQL.
   - Media uploads write to the configured bucket.
   - Runtime service account has no broad project-level permissions.

## Dev, Staging, And Prod Usage

All environment roots compose the same modules and expose similar variables. The differences are defaults.

`environments/dev` is lower-cost by default:

- Cloud Run min instances defaults to `0`.
- Cloud Run memory defaults to `512Mi`.
- Cloud Run max instances defaults to a low value.
- Cloud SQL tier defaults to `db-f1-micro`.
- Cloud SQL disk defaults to `10` GB.
- Cloud SQL deletion protection defaults to `false`.
- Cloud Run deletion protection defaults to `false`.

`environments/staging` is still modest but more protective:

- Cloud Run min instances defaults to `0`.
- Cloud Run max instances defaults higher than dev.
- Cloud SQL tier defaults to `db-g1-small`.
- Cloud SQL deletion protection defaults to `true`.
- Backups default to enabled.

`environments/prod` is safer by default:

- Cloud SQL deletion protection defaults to `true`.
- Cloud Run deletion protection defaults to `true`.
- Backups default to enabled.
- Cloud Run memory defaults to `1Gi`.
- Cloud Run max instances defaults higher than dev/staging.
- Cloud SQL disk defaults to `20` GB.

Each environment uses placeholder-only `terraform.tfvars.example` files. Do not commit real `.tfvars`, secrets, state files, or generated plan files.

## Image Build Expectations

Terraform does not build the app image. Build and push a container image before planning or applying, then pass its full reference as `container_image`.

Expected image behavior:

- The container must listen on the port provided by `PORT`; the default is `3000`.
- The image must be suitable for Cloud Run's container contract.
- The app should be built for production.
- The existing app Dockerfile expects Next's standalone output under `.next/standalone`.

Example shape for an image reference:

```hcl
container_image = "replace-with-region-docker.pkg.dev/replace-with-project/replace-with-repo/replace-with-image:replace-with-tag"
```

Artifact Registry can be created by the app module with `create_artifact_registry_repository = true`, but image publishing still happens outside Terraform.

## Migration Flow

Terraform creates infrastructure and secrets, but it does not run Payload migrations.

Recommended migration flow:

1. Provision or update infrastructure with Terraform.
2. Retrieve the Cloud SQL connection name and `DATABASE_URL` secret ID from Terraform outputs.
3. Run migrations from local or CI using a controlled database connection path, such as Cloud SQL Auth Proxy or an approved private network path.
4. Run:

   ```sh
   pnpm payload migrate
   ```

5. Deploy or roll the Cloud Run revision using the image intended for that schema.
6. Smoke-test public pages, `/admin`, API routes, database reads/writes, and media upload.

Keep migration permissions separate from the Cloud Run runtime service account when possible. The runtime service account is scoped for application runtime behavior, not broad operator access.

## Secrets And Terraform State

This Terraform creates several secrets:

- `DATABASE_URL`
- `PAYLOAD_SECRET`
- `S3_ACCESS_KEY_ID`
- `S3_SECRET_ACCESS_KEY`

Secret values are stored in Secret Manager, but generated secret values also pass through Terraform state. That includes generated database passwords, generated Payload secrets, and HMAC secrets.

State handling requirements:

- Use a secured remote backend for real environments.
- Restrict access to state storage.
- Enable bucket versioning and audit logging for state where appropriate.
- Do not commit `.tfstate`, `.tfvars`, generated plans, credentials, private keys, or copied secret values.
- Treat Terraform outputs that identify secret IDs as non-secret metadata; do not output secret values.

The `.gitignore` is configured to ignore state, plans, and real tfvars while allowing `.terraform.lock.hcl` and `.tfvars.example` files.

## Variables Overview

Common root variables:

- `project_id`: target GCP project.
- `region`: target GCP region.
- `app_name`: reusable application name used in resource naming.
- `environment`: lifecycle environment name.
- `instance_name`: tenant, municipality, or deployment instance name.
- `container_image`: full image reference deployed to Cloud Run.
- `labels`: additional GCP labels.
- `allow_unauthenticated`: whether Cloud Run gets public invoker access.
- `extra_env_vars`: non-secret app env vars, such as feature flags.

Cloud Run variables:

- `cloud_run_cpu`
- `cloud_run_memory`
- `min_instances`
- `max_instances`
- `concurrency`
- `cloud_run_deletion_protection`
- `create_artifact_registry_repository`
- `artifact_registry_repository_id`

Database variables:

- `database_version`
- `database_tier`
- `database_disk_size_gb`
- `database_disk_type`
- `database_deletion_protection`
- `database_backup_enabled`
- `database_ipv4_enabled`

Storage variables:

- `media_bucket_name`
- `bucket_location`
- `public_media`
- `create_hmac_key`
- `s3_endpoint`
- `s3_region`
- `grant_runtime_bucket_access`: opt-in direct media bucket access for the Cloud Run runtime service account. Leave `false` when using the default dedicated HMAC/S3 media credentials.

Networking variables:

- `create_network`
- `network_name`
- `create_serverless_connector`
- `connector_ip_cidr_range`

See the `variables.tf` file in each root and module for exact types, defaults, and validation rules.

## Outputs Overview

Environment roots expose the key values downstream operators need:

- `service_name`
- `service_url`
- `runtime_service_account_email`
- `cloud_sql_instance_name`
- `database_connection_name`
- `database_name`
- `database_user`
- `database_url_secret_id`
- `payload_secret_id`
- `s3_access_key_id_secret_id`
- `s3_secret_access_key_secret_id`
- `media_bucket_name`
- `media_bucket_url`
- `artifact_registry_repository_url`, when created

The multi-instance example outputs maps keyed by instance name for Cloud Run services, runtime service accounts, Cloud SQL connection names, and media buckets.

## Assumptions

- The default deployment target is GCP-managed/serverless infrastructure.
- Cloud Run plus the Cloud SQL connector is the default database connectivity path.
- Private VPC networking is optional and disabled by default.
- Media is public by default because the public site renders uploaded images and documents.
- Runtime service accounts should not receive broad project roles.
- Terraform manages infrastructure and generated secrets, not application migrations.
- Image build and image promotion happen outside Terraform.
- Environment roots should be backed by secured remote state before real use.
- No queues, Redis, Cloud Scheduler, email provider, or worker process is provisioned because the app repo does not currently show those runtime requirements.

## Validation Commands

Run formatting for the whole repository:

```sh
terraform fmt -recursive
```

Validate every runnable root:

```sh
terraform -chdir=environments/dev init -backend=false
terraform -chdir=environments/dev validate

terraform -chdir=environments/staging init -backend=false
terraform -chdir=environments/staging validate

terraform -chdir=environments/prod init -backend=false
terraform -chdir=environments/prod validate

terraform -chdir=examples/single-instance init -backend=false
terraform -chdir=examples/single-instance validate

terraform -chdir=examples/multi-instance init -backend=false
terraform -chdir=examples/multi-instance validate
```

Never run `terraform apply` or `terraform destroy` unless the action has been explicitly requested and reviewed.

## Known App-Side Follow-Ups

Do not make these changes from this repository unless the app repo owner explicitly asks for app edits.

- The app Dockerfile expects `.next/standalone`, but `next.config.ts` does not currently set `output: 'standalone'`. Add that before relying on the Dockerfile for Cloud Run images.
- If Payload's S3 adapter emits remote GCS/media URLs, add the chosen GCS/media host to `next.config.ts` image `remotePatterns`; the app currently only allows local `/api/media/file/**`.
- Confirm the exact production image build and push process for the app, including registry, repository, tag strategy, and CI permissions.
- Confirm the migration runner path, such as local/CI plus Cloud SQL Auth Proxy.
- Decide whether each deployment should enable optional app feature flags, such as `ENABLE_SHERIFF_SALES`.
