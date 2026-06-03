output "instance_name" {
  description = "Cloud SQL instance name."
  value       = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "Cloud SQL connection name."
  value       = google_sql_database_instance.this.connection_name
}

output "database_name" {
  description = "Application database name."
  value       = google_sql_database.app.name
}

output "database_user" {
  description = "Application database user."
  value       = google_sql_user.app.name
}

output "database_url_secret_id" {
  description = "Secret Manager secret ID for DATABASE_URL."
  value       = google_secret_manager_secret.database_url.secret_id
}

output "database_url_secret_version_id" {
  description = "Secret Manager version ID for DATABASE_URL."
  value       = google_secret_manager_secret_version.database_url.id
}

output "database_url" {
  description = "Generated DATABASE_URL. Prefer consuming database_url_secret_id."
  value       = local.database_url
  sensitive   = true
}
