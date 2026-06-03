locals {
  network_name              = coalesce(var.network_name, "${var.name_prefix}-network")
  serverless_connector_name = coalesce(var.serverless_connector_name, trimsuffix(substr("${var.name_prefix}-connector", 0, 24), "-"))
  connector_network_name    = var.create_network ? google_compute_network.this[0].name : var.network_name
}

resource "google_compute_network" "this" {
  count = var.create_network ? 1 : 0

  project                         = var.project_id
  name                            = local.network_name
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = var.delete_default_routes_on_create
}

resource "google_vpc_access_connector" "this" {
  count = var.create_serverless_connector ? 1 : 0

  project       = var.project_id
  region        = var.region
  name          = local.serverless_connector_name
  network       = local.connector_network_name
  ip_cidr_range = var.connector_ip_cidr_range
  min_instances = var.connector_min_instances
  max_instances = var.connector_max_instances
  machine_type  = var.connector_machine_type

  lifecycle {
    precondition {
      condition     = var.create_network || var.network_name != null
      error_message = "create_serverless_connector requires either create_network = true or network_name to reference an existing VPC."
    }

    precondition {
      condition     = var.connector_max_instances >= var.connector_min_instances
      error_message = "connector_max_instances must be greater than or equal to connector_min_instances."
    }
  }
}
