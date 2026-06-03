variable "project_id" {
  description = "GCP project ID where database resources will be created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID."
  }
}

variable "region" {
  description = "GCP region for the Cloud SQL instance."
  type        = string

  validation {
    condition     = length(var.region) > 0
    error_message = "region must not be empty."
  }
}

variable "name_prefix" {
  description = "Reusable lowercase prefix used for database-adjacent resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.name_prefix)) && length(var.name_prefix) <= 60
    error_message = "name_prefix must contain only lowercase letters, numbers, and hyphens, start with a letter, end with a letter or number, and be 60 characters or fewer."
  }
}

variable "instance_name" {
  description = "Cloud SQL instance name."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,96}[a-z0-9]$", var.instance_name))
    error_message = "instance_name must be a valid lowercase Cloud SQL instance name."
  }
}

variable "database_name" {
  description = "Application database name."
  type        = string
  default     = "app"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.database_name))
    error_message = "database_name must start with a lowercase letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "database_user" {
  description = "Application database user."
  type        = string
  default     = "app"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.database_user))
    error_message = "database_user must start with a lowercase letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "database_version" {
  description = "Cloud SQL PostgreSQL version."
  type        = string
  default     = "POSTGRES_16"

  validation {
    condition     = can(regex("^POSTGRES_[0-9]+$", var.database_version))
    error_message = "database_version must be a Cloud SQL PostgreSQL version such as POSTGRES_16."
  }
}

variable "database_tier" {
  description = "Cloud SQL machine tier."
  type        = string
  default     = "db-f1-micro"

  validation {
    condition     = length(var.database_tier) > 0
    error_message = "database_tier must not be empty."
  }
}

variable "database_disk_size_gb" {
  description = "Cloud SQL disk size in GB."
  type        = number
  default     = 10

  validation {
    condition     = var.database_disk_size_gb >= 10
    error_message = "database_disk_size_gb must be at least 10."
  }
}

variable "database_disk_type" {
  description = "Cloud SQL disk type."
  type        = string
  default     = "PD_HDD"

  validation {
    condition     = contains(["PD_HDD", "PD_SSD"], var.database_disk_type)
    error_message = "database_disk_type must be PD_HDD or PD_SSD."
  }
}

variable "availability_type" {
  description = "Cloud SQL availability type."
  type        = string
  default     = "ZONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "availability_type must be ZONAL or REGIONAL."
  }
}

variable "database_deletion_protection" {
  description = "Whether deletion protection is enabled for the database instance."
  type        = bool
  default     = true
}

variable "database_backup_enabled" {
  description = "Whether automated backups are enabled."
  type        = bool
  default     = true
}

variable "database_backup_start_time" {
  description = "UTC start time for automated backups in HH:MM format."
  type        = string
  default     = "03:00"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.database_backup_start_time))
    error_message = "database_backup_start_time must use HH:MM 24-hour format."
  }
}

variable "database_ipv4_enabled" {
  description = "Whether the Cloud SQL instance has a public IPv4 address. Cloud Run still uses the Cloud SQL connector."
  type        = bool
  default     = true
}

variable "database_password_length" {
  description = "Generated database password length."
  type        = number
  default     = 32

  validation {
    condition     = var.database_password_length >= 24
    error_message = "database_password_length must be at least 24."
  }
}

variable "database_url_secret_id" {
  description = "Optional Secret Manager secret ID for DATABASE_URL."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply to supported resources."
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
