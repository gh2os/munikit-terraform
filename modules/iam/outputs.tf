output "runtime_service_account_email" {
  description = "Runtime service account email."
  value       = google_service_account.runtime.email
}

output "runtime_service_account_id" {
  description = "Runtime service account resource ID."
  value       = google_service_account.runtime.id
}

output "runtime_member" {
  description = "IAM member string for the runtime service account."
  value       = "serviceAccount:${google_service_account.runtime.email}"
}

output "secret_accessor_secret_ids" {
  description = "Secret IDs with secretAccessor granted to the runtime service account."
  value       = sort(keys(google_secret_manager_secret_iam_member.secret_accessor))
}
