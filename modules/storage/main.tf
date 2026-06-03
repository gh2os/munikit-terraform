locals {
  hmac_service_account_id        = coalesce(var.hmac_service_account_id, trimsuffix(substr("${var.name_prefix}-hmac", 0, 30), "-"))
  s3_access_key_id_secret_id     = coalesce(var.s3_access_key_id_secret_id, "${var.name_prefix}-s3-access-key-id")
  s3_secret_access_key_secret_id = coalesce(var.s3_secret_access_key_secret_id, "${var.name_prefix}-s3-secret-access-key")
}

resource "google_storage_bucket" "media" {
  project                     = var.project_id
  name                        = var.bucket_name
  location                    = var.bucket_location
  storage_class               = var.storage_class
  uniform_bucket_level_access = var.uniform_bucket_level_access
  public_access_prevention    = var.public_media ? "inherited" : "enforced"
  force_destroy               = var.force_destroy
  labels                      = var.labels

  versioning {
    enabled = var.versioning_enabled
  }

  dynamic "cors" {
    for_each = var.cors_rules

    content {
      origin          = cors.value.origins
      method          = cors.value.methods
      response_header = cors.value.response_headers
      max_age_seconds = cors.value.max_age_seconds
    }
  }
}

resource "google_storage_bucket_iam_member" "public_reader" {
  count = var.public_media ? 1 : 0

  bucket = google_storage_bucket.media.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_service_account" "hmac" {
  count = var.create_hmac_key ? 1 : 0

  project      = var.project_id
  account_id   = local.hmac_service_account_id
  display_name = "Media HMAC credentials"
  description  = "Service account used for S3-compatible media access for ${var.name_prefix}."
}

resource "google_storage_bucket_iam_member" "hmac_object_access" {
  count = var.create_hmac_key ? 1 : 0

  bucket = google_storage_bucket.media.name
  role   = var.hmac_bucket_role
  member = "serviceAccount:${google_service_account.hmac[0].email}"
}

resource "google_storage_hmac_key" "media" {
  count = var.create_hmac_key ? 1 : 0

  project               = var.project_id
  service_account_email = google_service_account.hmac[0].email
}

resource "google_secret_manager_secret" "s3_access_key_id" {
  count = var.create_hmac_key ? 1 : 0

  project   = var.project_id
  secret_id = local.s3_access_key_id_secret_id
  labels    = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "s3_access_key_id" {
  count = var.create_hmac_key ? 1 : 0

  secret      = google_secret_manager_secret.s3_access_key_id[0].id
  secret_data = google_storage_hmac_key.media[0].access_id
}

resource "google_secret_manager_secret" "s3_secret_access_key" {
  count = var.create_hmac_key ? 1 : 0

  project   = var.project_id
  secret_id = local.s3_secret_access_key_secret_id
  labels    = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "s3_secret_access_key" {
  count = var.create_hmac_key ? 1 : 0

  secret      = google_secret_manager_secret.s3_secret_access_key[0].id
  secret_data = google_storage_hmac_key.media[0].secret
}
