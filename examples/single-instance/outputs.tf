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

output "database_connection_name" {
  description = "Cloud SQL connection name."
  value       = module.database.connection_name
}

output "media_bucket_name" {
  description = "Media bucket name."
  value       = module.storage.bucket_name
}
