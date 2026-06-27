output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_address_space" {
  description = "The address space of the virtual network"
  value       = azurerm_virtual_network.vnet.address_space
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID"
  value       = { for k, v in azurerm_subnet.subnet : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet name to address prefixes"
  value       = { for k, v in azurerm_subnet.subnet : k => v.address_prefixes }
}

output "nsg_ids" {
  description = "Map of subnet name to NSG ID (only for subnets with NSG rules)"
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}
