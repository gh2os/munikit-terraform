variable "project_id" {
  description = "GCP project ID for this environment."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID."
  }
}

variable "region" {
  description = "GCP region for regional resources."
  type        = string

  validation {
    condition     = length(var.region) > 0
    error_message = "region must not be empty."
  }
}

variable "app_name" {
  description = "Application name used for resource naming."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.app_name))
    error_message = "app_name must contain only lowercase letters, numbers, and hyphens, start with a letter, and end with a letter or number."
  }
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "staging"

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.environment))
    error_message = "environment must contain only lowercase letters, numbers, and hyphens, start with a letter, and end with a letter or number."
  }
}

variable "instance_name" {
  description = "Tenant or instance name."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.instance_name))
    error_message = "instance_name must contain only lowercase letters, numbers, and hyphens, start with a letter, and end with a letter or number."
  }
}

variable "container_image" {
  description = "Fully qualified container image to deploy."
  type        = string
}

variable "labels" {
  description = "Additional labels to apply to supported resources."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.labels :
      can(regex("^[a-z][a-z0-9_-]{0,62}$", key)) &&
      (value == "" || can(regex("^[a-z0-9][a-z0-9_-]{0,62}$", value)))
    ])
    error_message = "labels must use GCP-compatible lowercase label keys and values."
  }
}

variable "create_network" {
  description = "Whether to create a VPC network."
  type        = bool
  default     = false
}

variable "network_name" {
  description = "Existing VPC network name, or optional name for a created network."
  type        = string
  default     = null
}

variable "create_serverless_connector" {
  description = "Whether to create a Serverless VPC Access connector."
  type        = bool
  default     = false
}

variable "connector_ip_cidr_range" {
  description = "IP CIDR range for the Serverless VPC Access connector."
  type        = string
  default     = "10.8.0.0/28"
}

variable "allow_unauthenticated" {
  description = "Whether to allow public invocations."
  type        = bool
  default     = true
}

variable "cloud_run_cpu" {
  description = "Cloud Run CPU allocation."
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Cloud Run memory allocation."
  type        = string
  default     = "512Mi"
}

variable "min_instances" {
  description = "Minimum Cloud Run instances."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum Cloud Run instances."
  type        = number
  default     = 5
}

variable "concurrency" {
  description = "Maximum concurrent requests per Cloud Run instance."
  type        = number
  default     = 80
}

variable "database_version" {
  description = "Cloud SQL PostgreSQL version."
  type        = string
  default     = "POSTGRES_16"
}

variable "database_tier" {
  description = "Cloud SQL machine tier."
  type        = string
  default     = "db-g1-small"
}

variable "database_disk_size_gb" {
  description = "Cloud SQL disk size in GB."
  type        = number
  default     = 10
}

variable "database_disk_type" {
  description = "Cloud SQL disk type."
  type        = string
  default     = "PD_HDD"
}

variable "database_deletion_protection" {
  description = "Whether deletion protection is enabled for the database."
  type        = bool
  default     = true
}

variable "database_backup_enabled" {
  description = "Whether automated database backups are enabled."
  type        = bool
  default     = true
}

variable "database_ipv4_enabled" {
  description = "Whether the Cloud SQL instance has a public IPv4 address. Cloud Run still uses the Cloud SQL connector."
  type        = bool
  default     = true
}

variable "media_bucket_name" {
  description = "Optional explicit media bucket name."
  type        = string
  default     = null
}

variable "bucket_location" {
  description = "Cloud Storage bucket location."
  type        = string
  default     = "US"
}

variable "public_media" {
  description = "Whether media should be publicly readable."
  type        = bool
  default     = true
}

variable "create_hmac_key" {
  description = "Whether to create S3-compatible HMAC credentials for media storage."
  type        = bool
  default     = true
}

variable "s3_endpoint" {
  description = "S3-compatible endpoint for media storage."
  type        = string
  default     = "https://storage.googleapis.com"
}

variable "s3_region" {
  description = "S3-compatible region for media storage."
  type        = string
  default     = "auto"
}

variable "grant_runtime_bucket_access" {
  description = "Whether the runtime service account should receive bucket-scoped object access."
  type        = bool
  default     = true
}

variable "cloud_run_deletion_protection" {
  description = "Whether deletion protection is enabled on the Cloud Run service."
  type        = bool
  default     = false
}

variable "create_artifact_registry_repository" {
  description = "Whether to create an Artifact Registry Docker repository."
  type        = bool
  default     = false
}

variable "artifact_registry_repository_id" {
  description = "Optional Artifact Registry repository ID."
  type        = string
  default     = null
}

variable "extra_env_vars" {
  description = "Non-secret environment variables for the app."
  type        = map(string)
  default     = {}
}
