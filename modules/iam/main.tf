locals {
  name_hash                          = substr(sha1(var.name_prefix), 0, 6)
  default_runtime_service_account_id = length("${var.name_prefix}-run") >= 6 && length("${var.name_prefix}-run") <= 30 ? "${var.name_prefix}-run" : "${trimsuffix(substr(var.name_prefix, 0, 19), "-")}-${local.name_hash}-run"
  runtime_service_account_id         = coalesce(var.runtime_service_account_id, local.default_runtime_service_account_id)
}

resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = local.runtime_service_account_id
  display_name = var.runtime_service_account_display_name
  description  = "Runtime service account for ${var.name_prefix}."
}

resource "google_project_iam_member" "cloud_sql_client" {
  count = var.grant_cloud_sql_client ? 1 : 0

  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  for_each = var.secret_ids

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_storage_bucket_iam_member" "media_object_access" {
  count = var.media_bucket_name != null && var.grant_media_bucket_object_access ? 1 : 0

  bucket = var.media_bucket_name
  role   = var.media_bucket_role
  member = "serviceAccount:${google_service_account.runtime.email}"
}
