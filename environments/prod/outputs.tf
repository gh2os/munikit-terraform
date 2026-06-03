output "service_name" {
  description = "Cloud Run service name."
  value       = module.app.service_name
}

output "service_url" {
  description = "Cloud Run service URL."
  value       = module.app.service_url
}

output "runtime_service_account_email" {
  description = "Runtime service account email."
  value       = module.iam.runtime_service_account_email
}

output "cloud_sql_instance_name" {
  description = "Cloud SQL instance name."
  value       = module.database.instance_name
}

output "database_connection_name" {
  description = "Cloud SQL connection name."
  value       = module.database.connection_name
}

output "database_name" {
  description = "Application database name."
  value       = module.database.database_name
}

output "database_user" {
  description = "Application database user."
  value       = module.database.database_user
}

output "database_url_secret_id" {
  description = "Secret Manager secret ID for DATABASE_URL."
  value       = module.database.database_url_secret_id
}

output "payload_secret_id" {
  description = "Secret Manager secret ID for PAYLOAD_SECRET."
  value       = module.app.payload_secret_id
}

output "s3_access_key_id_secret_id" {
  description = "Secret Manager secret ID for S3_ACCESS_KEY_ID."
  value       = module.storage.s3_access_key_id_secret_id
}

output "s3_secret_access_key_secret_id" {
  description = "Secret Manager secret ID for S3_SECRET_ACCESS_KEY."
  value       = module.storage.s3_secret_access_key_secret_id
}

output "media_bucket_name" {
  description = "Media bucket name."
  value       = module.storage.bucket_name
}

output "media_bucket_url" {
  description = "Media bucket URL."
  value       = module.storage.bucket_url
}

output "artifact_registry_repository_url" {
  description = "Artifact Registry repository URL, when created."
  value       = module.app.artifact_registry_repository_url
}
