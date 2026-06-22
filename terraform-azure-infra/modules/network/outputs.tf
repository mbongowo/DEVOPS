output "vnet_id" {
  description = "Virtual network resource ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name => subnet ID."
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "nsg_id" {
  description = "Network security group resource ID."
  value       = azurerm_network_security_group.this.id
}
