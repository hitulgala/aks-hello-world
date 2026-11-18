# Outputs of the aks module.
output "id" {
  description = "Cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "Cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "node_resource_group" {
  description = "Resource group AKS manages for nodes, disks and load balancers."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "kubelet_object_id" {
  description = "Object ID of the kubelet identity (pulls images)."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL, used for workload identity."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}
