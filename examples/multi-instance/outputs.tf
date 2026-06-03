output "service_names" {
  description = "Cloud Run service names."
  value       = { for name, instance in module.app : name => instance.service_name }
}

output "service_urls" {
  description = "Cloud Run service URLs."
  value       = { for name, instance in module.app : name => instance.service_url }
}

output "runtime_service_account_emails" {
  description = "Runtime service account emails."
  value       = { for name, instance in module.iam : name => instance.runtime_service_account_email }
}

output "database_connection_names" {
  description = "Cloud SQL connection names."
  value       = { for name, instance in module.database : name => instance.connection_name }
}

output "media_bucket_names" {
  description = "Media bucket names."
  value       = { for name, instance in module.storage : name => instance.bucket_name }
}
