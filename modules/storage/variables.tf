variable "project_id" {
  description = "GCP project ID where storage resources will be created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID."
  }
}

variable "name_prefix" {
  description = "Reusable lowercase prefix used for service account and secret names."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.name_prefix)) && length(var.name_prefix) <= 60
    error_message = "name_prefix must contain only lowercase letters, numbers, and hyphens, start with a letter, end with a letter or number, and be 60 characters or fewer."
  }
}

variable "bucket_name" {
  description = "Cloud Storage bucket name for media."
  type        = string

  validation {
    condition = can(regex("^[a-z0-9][a-z0-9._-]{1,220}[a-z0-9]$", var.bucket_name)) && !startswith(var.bucket_name, "goog") && !can(regex("g[o0]{2}g[l1]e", var.bucket_name)) && !can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.bucket_name)) && (
      length(split(".", var.bucket_name)) > 1 ? (
        length(var.bucket_name) <= 222 &&
        alltrue([
          for label in split(".", var.bucket_name) :
          length(label) <= 63 && can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", label))
        ])
        ) : (
        length(var.bucket_name) <= 63
      )
    )
    error_message = "bucket_name must be a valid Cloud Storage bucket name. Dotless names must be 63 characters or fewer; dotted names may be up to 222 characters with each component 63 characters or fewer, and names must not look like an IPv4 address, start with goog, or contain google/g00gle-like reserved names."
  }
}

variable "bucket_location" {
  description = "Cloud Storage bucket location."
  type        = string
  default     = "US"

  validation {
    condition     = length(var.bucket_location) > 0
    error_message = "bucket_location must not be empty."
  }
}

variable "storage_class" {
  description = "Default storage class for the media bucket."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "storage_class must be STANDARD, NEARLINE, COLDLINE, or ARCHIVE."
  }
}

variable "public_media" {
  description = "Whether uploaded media should be publicly readable."
  type        = bool
  default     = true
}

variable "uniform_bucket_level_access" {
  description = "Whether uniform bucket-level access is enabled."
  type        = bool
  default     = true
}

variable "versioning_enabled" {
  description = "Whether object versioning is enabled on the media bucket."
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Whether Terraform may delete a bucket that still contains objects."
  type        = bool
  default     = false
}

variable "cors_rules" {
  description = "Optional CORS rules for the media bucket."
  type = list(object({
    origins          = list(string)
    methods          = list(string)
    response_headers = list(string)
    max_age_seconds  = number
  }))
  default = []
}

variable "create_hmac_key" {
  description = "Whether to create a service account and HMAC key for S3-compatible access."
  type        = bool
  default     = true
}

variable "hmac_service_account_id" {
  description = "Optional service account ID for S3-compatible HMAC credentials."
  type        = string
  default     = null

  validation {
    condition     = var.hmac_service_account_id == null ? true : (can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.hmac_service_account_id)) && length(var.hmac_service_account_id) <= 30)
    error_message = "hmac_service_account_id must be 6-30 characters, lowercase, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "hmac_bucket_role" {
  description = "Bucket-scoped role for the HMAC service account."
  type        = string
  default     = "roles/storage.objectUser"

  validation {
    condition     = contains(["roles/storage.objectUser", "roles/storage.objectViewer"], var.hmac_bucket_role)
    error_message = "hmac_bucket_role must be a least-privilege Cloud Storage object role."
  }
}

variable "s3_endpoint" {
  description = "S3-compatible endpoint value to expose to the application."
  type        = string
  default     = "https://storage.googleapis.com"
}

variable "s3_region" {
  description = "S3-compatible region value to expose to the application."
  type        = string
  default     = "auto"
}

variable "s3_access_key_id_secret_id" {
  description = "Optional Secret Manager secret ID for S3_ACCESS_KEY_ID."
  type        = string
  default     = null
}

variable "s3_secret_access_key_secret_id" {
  description = "Optional Secret Manager secret ID for S3_SECRET_ACCESS_KEY."
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
