# Outputs of the network module.
output "vnet_id" {
  description = "Virtual network ID."
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "Subnet IDs keyed by the same logical keys as var.subnets."
  value       = { for key, subnet in azurerm_subnet.this : key => subnet.id }
}
