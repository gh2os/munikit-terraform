variable "project_id" {
  description = "GCP project ID where networking resources may be created."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID."
  }
}

variable "region" {
  description = "GCP region for regional networking resources."
  type        = string

  validation {
    condition     = length(var.region) > 0
    error_message = "region must not be empty."
  }
}

variable "name_prefix" {
  description = "Reusable prefix for networking resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.name_prefix)) && length(var.name_prefix) <= 60
    error_message = "name_prefix must contain only lowercase letters, numbers, and hyphens, start with a letter, end with a letter or number, and be 60 characters or fewer."
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

variable "auto_create_subnetworks" {
  description = "Whether a created VPC should automatically create subnetworks."
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "Routing mode for a created VPC."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "delete_default_routes_on_create" {
  description = "Whether default routes should be deleted on a created VPC."
  type        = bool
  default     = false
}

variable "create_serverless_connector" {
  description = "Whether to create a Serverless VPC Access connector."
  type        = bool
  default     = false
}

variable "serverless_connector_name" {
  description = "Optional Serverless VPC Access connector name."
  type        = string
  default     = null
}

variable "connector_ip_cidr_range" {
  description = "IP CIDR range for the Serverless VPC Access connector."
  type        = string
  default     = "10.8.0.0/28"
}

variable "connector_min_instances" {
  description = "Minimum connector instances."
  type        = number
  default     = 2

  validation {
    condition     = var.connector_min_instances >= 2
    error_message = "connector_min_instances must be at least 2."
  }
}

variable "connector_max_instances" {
  description = "Maximum connector instances."
  type        = number
  default     = 3

  validation {
    condition     = var.connector_max_instances >= 2
    error_message = "connector_max_instances must be at least 2."
  }
}

variable "connector_machine_type" {
  description = "Machine type for the Serverless VPC Access connector."
  type        = string
  default     = "e2-micro"
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
