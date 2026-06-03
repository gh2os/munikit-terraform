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

variable "instance_name" {
  description = "Example instance name."
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

variable "extra_env_vars" {
  description = "Non-secret environment variables for the app."
  type        = map(string)
  default     = {}
}
