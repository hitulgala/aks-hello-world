# Outputs of the dev-centralindia stack.
output "resource_group_name" {
  description = "Project resource group."
  value       = azurerm_resource_group.main.name
}

output "acr_name" {
  description = "Container registry name (for az acr login)."
  value       = module.container_registry.name
}

output "acr_login_server" {
  description = "Registry login server, used in image names."
  value       = module.container_registry.login_server
}

output "aks_name" {
  description = "AKS cluster name."
  value       = module.aks.name
}

output "aks_node_resource_group" {
  description = "Resource group AKS manages for nodes. Do not edit it by hand."
  value       = module.aks.node_resource_group
}

output "get_credentials_command" {
  description = "Command that adds this cluster to your kubeconfig."
  value       = "az aks get-credentials -g ${azurerm_resource_group.main.name} -n ${module.aks.name}"
}
