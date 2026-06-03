variable "project_id" {
  description = "GCP project ID where the application will run."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID."
  }
}

variable "region" {
  description = "GCP region for regional application resources."
  type        = string

  validation {
    condition     = length(var.region) > 0
    error_message = "region must not be empty."
  }
}

variable "app_name" {
  description = "Reusable application name used for resource naming."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.app_name)) && length(var.app_name) <= 40
    error_message = "app_name must contain only lowercase letters, numbers, and hyphens, start with a letter, and end with a letter or number."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.environment)) && length(var.environment) <= 30
    error_message = "environment must contain only lowercase letters, numbers, and hyphens, start with a letter, and end with a letter or number."
  }
}

variable "instance_name" {
  description = "Specific tenant or instance name."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.instance_name)) && length(var.instance_name) <= 40
    error_message = "instance_name must contain only lowercase letters, numbers, and hyphens, start with a letter, and end with a letter or number."
  }
}

variable "service_name" {
  description = "Optional Cloud Run service name. Defaults to app_name-environment-instance_name."
  type        = string
  default     = null

  validation {
    condition     = var.service_name == null || (can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.service_name)) && length(var.service_name) <= 49)
    error_message = "service_name must be a valid Cloud Run service name with 49 characters or fewer."
  }
}

variable "runtime_service_account_email" {
  description = "Runtime service account email used by Cloud Run."
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.iam\\.gserviceaccount\\.com$", var.runtime_service_account_email))
    error_message = "runtime_service_account_email must be a service account email."
  }
}

variable "container_image" {
  description = "Fully qualified container image for Cloud Run."
  type        = string

  validation {
    condition     = length(var.container_image) > 0
    error_message = "container_image must not be empty."
  }
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

variable "allow_unauthenticated" {
  description = "Whether the application should allow public invocations."
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

  validation {
    condition     = var.min_instances >= 0
    error_message = "min_instances must be zero or greater."
  }
}

variable "max_instances" {
  description = "Maximum Cloud Run instances."
  type        = number
  default     = 3

  validation {
    condition     = var.max_instances >= 1
    error_message = "max_instances must be at least 1."
  }
}

variable "concurrency" {
  description = "Maximum concurrent requests per Cloud Run instance."
  type        = number
  default     = 80

  validation {
    condition     = var.concurrency >= 1 && var.concurrency <= 1000
    error_message = "concurrency must be between 1 and 1000."
  }
}

variable "port" {
  description = "Container port exposed by the runtime image."
  type        = number
  default     = 3000

  validation {
    condition     = var.port > 0 && var.port <= 65535
    error_message = "port must be a valid TCP port."
  }
}

variable "request_timeout_seconds" {
  description = "Cloud Run request timeout in seconds."
  type        = number
  default     = 300

  validation {
    condition     = var.request_timeout_seconds >= 1 && var.request_timeout_seconds <= 3600
    error_message = "request_timeout_seconds must be between 1 and 3600."
  }
}

variable "ingress" {
  description = "Cloud Run ingress setting."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"

  validation {
    condition = contains([
      "INGRESS_TRAFFIC_ALL",
      "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER",
    ], var.ingress)
    error_message = "ingress must be a supported Cloud Run v2 ingress value."
  }
}

variable "cpu_idle" {
  description = "Whether CPU is only allocated during request processing."
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "Whether startup CPU boost is enabled."
  type        = bool
  default     = true
}

variable "cloud_sql_connection_name" {
  description = "Optional Cloud SQL connection name to mount at /cloudsql."
  type        = string
  default     = null
}

variable "database_url_secret_id" {
  description = "Secret Manager secret ID for DATABASE_URL."
  type        = string
  default     = null
}

variable "payload_secret" {
  description = "Optional PAYLOAD_SECRET value. When null, a secret is generated."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.payload_secret == null || length(var.payload_secret) >= 32
    error_message = "payload_secret must be at least 32 characters when provided."
  }
}

variable "payload_secret_id" {
  description = "Optional Secret Manager secret ID for PAYLOAD_SECRET."
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "Optional S3-compatible bucket name for Payload media."
  type        = string
  default     = null
}

variable "s3_endpoint" {
  description = "Optional S3-compatible endpoint for Payload media."
  type        = string
  default     = null
}

variable "s3_region" {
  description = "Optional S3-compatible region for Payload media."
  type        = string
  default     = null
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

variable "serverless_vpc_connector_id" {
  description = "Optional Serverless VPC Access connector ID."
  type        = string
  default     = null
}

variable "vpc_egress" {
  description = "VPC egress behavior when serverless_vpc_connector_id is set."
  type        = string
  default     = "PRIVATE_RANGES_ONLY"

  validation {
    condition     = contains(["PRIVATE_RANGES_ONLY", "ALL_TRAFFIC"], var.vpc_egress)
    error_message = "vpc_egress must be PRIVATE_RANGES_ONLY or ALL_TRAFFIC."
  }
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled for the Cloud Run service."
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

  validation {
    condition     = var.artifact_registry_repository_id == null || (can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.artifact_registry_repository_id)) && length(var.artifact_registry_repository_id) <= 63)
    error_message = "artifact_registry_repository_id must be a valid lowercase Artifact Registry repository ID."
  }
}

variable "extra_env_vars" {
  description = "Non-secret environment variables to pass to the application."
  type        = map(string)
  default     = {}

  validation {
    condition = length(setintersection(
      toset(keys(var.extra_env_vars)),
      toset([
        "DATABASE_URL",
        "NODE_ENV",
        "PAYLOAD_SECRET",
        "PORT",
        "S3_ACCESS_KEY_ID",
        "S3_BUCKET",
        "S3_ENDPOINT",
        "S3_REGION",
        "S3_SECRET_ACCESS_KEY",
      ])
    )) == 0
    error_message = "extra_env_vars must not override managed runtime or secret environment variables."
  }
}
