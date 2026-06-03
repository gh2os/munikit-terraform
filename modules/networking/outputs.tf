output "network_name" {
  description = "VPC network name, either created or provided."
  value       = var.create_network || var.network_name != null ? local.network_name : null
}

output "network_self_link" {
  description = "Created VPC network self link."
  value       = var.create_network ? google_compute_network.this[0].self_link : null
}

output "serverless_connector_name" {
  description = "Serverless VPC connector name."
  value       = var.create_serverless_connector ? google_vpc_access_connector.this[0].name : null
}

output "serverless_connector_id" {
  description = "Serverless VPC connector ID for Cloud Run."
  value       = var.create_serverless_connector ? google_vpc_access_connector.this[0].id : null
}
