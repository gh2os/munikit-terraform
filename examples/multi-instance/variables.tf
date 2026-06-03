variable "project_id" {
  description = "GCP project ID for the example."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID."
  }
}

variable "region" {
  description = "GCP region for the example."
  type        = string
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
  description = "Example environment name."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.environment))
    error_message = "environment must contain only lowercase letters, numbers, and hyphens, start with a letter, and end with a letter or number."
  }
}

variable "labels" {
  description = "Additional labels to apply to supported resources."
  type        = map(string)
  default     = {}
}

variable "bucket_location" {
  description = "Cloud Storage bucket location."
  type        = string
  default     = "US"
}

variable "instances" {
  description = "Application instances keyed by instance name."
  type = map(object({
    container_image       = string
    allow_unauthenticated = optional(bool, true)
    extra_env_vars        = optional(map(string), {})
    media_bucket_name     = optional(string)
  }))

  validation {
    condition = alltrue([
      for name, instance in var.instances :
      can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", name))
    ])
    error_message = "Instance keys must contain only lowercase letters, numbers, and hyphens, start with a letter, and end with a letter or number."
  }
}
