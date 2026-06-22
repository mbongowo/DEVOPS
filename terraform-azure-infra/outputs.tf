output "resource_group_name" {
  description = "Name of the created resource group."
  value       = module.resource_group.name
}

output "location" {
  description = "Azure region the stack is deployed to."
  value       = module.resource_group.location
}

output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name => subnet ID."
  value       = module.network.subnet_ids
}

output "webapp_default_hostname" {
  description = "Public hostname of the web app."
  value       = module.webapp.default_hostname
}

output "webapp_url" {
  description = "HTTPS URL of the web app."
  value       = "https://${module.webapp.default_hostname}"
}
