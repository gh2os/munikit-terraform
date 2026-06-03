output "service_name" {
  description = "Cloud Run service name."
  value       = google_cloud_run_v2_service.this.name
}

output "service_url" {
  description = "Cloud Run service URL."
  value       = google_cloud_run_v2_service.this.uri
}

output "runtime_service_account_email" {
  description = "Runtime service account email."
  value       = var.runtime_service_account_email
}

output "payload_secret_id" {
  description = "Secret Manager secret ID for PAYLOAD_SECRET."
  value       = google_secret_manager_secret.payload_secret.secret_id
}

output "managed_secret_ids" {
  description = "Secret IDs managed directly by this module."
  value       = [google_secret_manager_secret.payload_secret.secret_id]
}

output "artifact_registry_repository_url" {
  description = "Artifact Registry repository URL, when created."
  value       = var.create_artifact_registry_repository ? "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container[0].repository_id}" : null
}
