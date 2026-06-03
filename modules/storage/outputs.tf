output "bucket_name" {
  description = "Media bucket name."
  value       = google_storage_bucket.media.name
}

output "bucket_url" {
  description = "Media bucket URL."
  value       = google_storage_bucket.media.url
}

output "hmac_service_account_email" {
  description = "Service account email used for S3-compatible HMAC credentials."
  value       = var.create_hmac_key ? google_service_account.hmac[0].email : null
}

output "s3_endpoint" {
  description = "S3-compatible endpoint for the media bucket."
  value       = var.s3_endpoint
}

output "s3_region" {
  description = "S3-compatible region for the media bucket."
  value       = var.s3_region
}

output "s3_access_key_id_secret_id" {
  description = "Secret Manager secret ID for S3_ACCESS_KEY_ID."
  value       = var.create_hmac_key ? google_secret_manager_secret.s3_access_key_id[0].secret_id : null
}

output "s3_secret_access_key_secret_id" {
  description = "Secret Manager secret ID for S3_SECRET_ACCESS_KEY."
  value       = var.create_hmac_key ? google_secret_manager_secret.s3_secret_access_key[0].secret_id : null
}
