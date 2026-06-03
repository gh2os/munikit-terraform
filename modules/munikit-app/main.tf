locals {
  name_prefix                     = "${var.app_name}-${var.environment}-${var.instance_name}"
  name_hash                       = substr(sha1(local.name_prefix), 0, 6)
  default_service_name            = length(local.name_prefix) <= 49 ? local.name_prefix : "${trimsuffix(substr(local.name_prefix, 0, 42), "-")}-${local.name_hash}"
  service_name                    = coalesce(var.service_name, local.default_service_name)
  payload_secret_id               = coalesce(var.payload_secret_id, "${local.name_prefix}-payload-secret")
  default_repository_id           = length("${local.name_prefix}-containers") <= 63 ? "${local.name_prefix}-containers" : "${trimsuffix(substr(local.name_prefix, 0, 45), "-")}-${local.name_hash}-containers"
  artifact_registry_repository_id = coalesce(var.artifact_registry_repository_id, local.default_repository_id)

  plain_env_vars = merge(
    {
      NODE_ENV = "production"
      PORT     = tostring(var.port)
    },
    var.s3_bucket == null ? {} : { S3_BUCKET = var.s3_bucket },
    var.s3_endpoint == null ? {} : { S3_ENDPOINT = var.s3_endpoint },
    var.s3_region == null ? {} : { S3_REGION = var.s3_region },
    var.extra_env_vars,
  )

  secret_env_vars = merge(
    var.database_url_secret_id == null ? {} : { DATABASE_URL = var.database_url_secret_id },
    { PAYLOAD_SECRET = google_secret_manager_secret.payload_secret.secret_id },
    var.s3_access_key_id_secret_id == null ? {} : { S3_ACCESS_KEY_ID = var.s3_access_key_id_secret_id },
    var.s3_secret_access_key_secret_id == null ? {} : { S3_SECRET_ACCESS_KEY = var.s3_secret_access_key_secret_id },
  )
}

resource "random_password" "payload_secret" {
  length           = 48
  special          = true
  override_special = "_-~."
}

resource "google_secret_manager_secret" "payload_secret" {
  project   = var.project_id
  secret_id = local.payload_secret_id
  labels    = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "payload_secret" {
  secret      = google_secret_manager_secret.payload_secret.id
  secret_data = coalesce(var.payload_secret, random_password.payload_secret.result)
}

resource "google_secret_manager_secret_iam_member" "payload_secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.payload_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.runtime_service_account_email}"
}

resource "google_artifact_registry_repository" "container" {
  count = var.create_artifact_registry_repository ? 1 : 0

  project       = var.project_id
  location      = var.region
  repository_id = local.artifact_registry_repository_id
  description   = "Container images for ${local.name_prefix}."
  format        = "DOCKER"
  labels        = var.labels
}

resource "google_cloud_run_v2_service" "this" {
  project             = var.project_id
  name                = local.service_name
  location            = var.region
  ingress             = var.ingress
  labels              = var.labels
  deletion_protection = var.deletion_protection

  template {
    service_account                  = var.runtime_service_account_email
    max_instance_request_concurrency = var.concurrency
    timeout                          = "${var.request_timeout_seconds}s"
    labels                           = var.labels

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    dynamic "vpc_access" {
      for_each = var.serverless_vpc_connector_id == null ? [] : [var.serverless_vpc_connector_id]

      content {
        connector = vpc_access.value
        egress    = var.vpc_egress
      }
    }

    containers {
      image = var.container_image

      ports {
        name           = "http1"
        container_port = var.port
      }

      resources {
        limits = {
          cpu    = var.cloud_run_cpu
          memory = var.cloud_run_memory
        }

        cpu_idle          = var.cpu_idle
        startup_cpu_boost = var.startup_cpu_boost
      }

      dynamic "env" {
        for_each = local.plain_env_vars

        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = local.secret_env_vars

        content {
          name = env.key

          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      dynamic "volume_mounts" {
        for_each = var.cloud_sql_connection_name == null ? [] : [var.cloud_sql_connection_name]

        content {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }
    }

    dynamic "volumes" {
      for_each = var.cloud_sql_connection_name == null ? [] : [var.cloud_sql_connection_name]

      content {
        name = "cloudsql"

        cloud_sql_instance {
          instances = [volumes.value]
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_secret_manager_secret_iam_member.payload_secret_accessor,
    google_secret_manager_secret_version.payload_secret,
  ]

  lifecycle {
    precondition {
      condition     = var.max_instances >= var.min_instances
      error_message = "max_instances must be greater than or equal to min_instances."
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = var.project_id
  location = google_cloud_run_v2_service.this.location
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
