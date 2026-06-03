variable "project_id" {
  description = "GCP project ID where IAM bindings may be created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID."
  }
}

variable "name_prefix" {
  description = "Reusable lowercase prefix used when creating IAM resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.name_prefix)) && length(var.name_prefix) <= 60
    error_message = "name_prefix must contain only lowercase letters, numbers, and hyphens, start with a letter, end with a letter or number, and be 60 characters or fewer."
  }
}

variable "runtime_service_account_id" {
  description = "Optional account ID for the runtime service account. Defaults to a value derived from name_prefix."
  type        = string
  default     = null

  validation {
    condition     = var.runtime_service_account_id == null ? true : (can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.runtime_service_account_id)) && length(var.runtime_service_account_id) <= 30)
    error_message = "runtime_service_account_id must be 6-30 characters, lowercase, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "runtime_service_account_display_name" {
  description = "Display name for the runtime service account."
  type        = string
  default     = "Application runtime"
}

variable "secret_ids" {
  description = "Secret Manager secret IDs the runtime service account may access."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for secret_id in var.secret_ids : length(secret_id) > 0])
    error_message = "secret_ids must not contain empty values."
  }
}

variable "media_bucket_name" {
  description = "Media bucket name for bucket-scoped IAM permissions."
  type        = string
  default     = null
}

variable "grant_cloud_sql_client" {
  description = "Whether to grant roles/cloudsql.client to the runtime service account in the project."
  type        = bool
  default     = true
}

variable "grant_media_bucket_object_access" {
  description = "Whether to grant bucket-scoped object access to the runtime service account when media_bucket_name is set. Keep false when the app uses dedicated HMAC/S3 credentials."
  type        = bool
  default     = false
}

variable "media_bucket_role" {
  description = "Bucket-scoped role to grant to the runtime service account."
  type        = string
  default     = "roles/storage.objectUser"

  validation {
    condition     = contains(["roles/storage.objectUser", "roles/storage.objectViewer"], var.media_bucket_role)
    error_message = "media_bucket_role must be a least-privilege Cloud Storage object role."
  }
}
