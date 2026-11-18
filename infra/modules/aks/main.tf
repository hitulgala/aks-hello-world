# ==============================================================================
# Module  : aks
# Purpose : AKS cluster with Entra ID authentication and Azure RBAC, Azure CNI
#           Overlay networking, plus the role assignments the cluster needs.
#
# Role assignments created here:
#   - AcrPull            : kubelet identity -> registry  (pull images, no secrets)
#   - Network Contributor: cluster identity -> node subnet (e.g. internal LBs)
#   - AKS RBAC Cluster Admin: each admin principal -> cluster (kubectl access)
# ==============================================================================
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  node_resource_group = var.node_resource_group_name
  sku_tier            = var.sku_tier
  kubernetes_version  = var.kubernetes_version

  automatic_upgrade_channel = var.automatic_upgrade_channel
  node_os_upgrade_channel   = var.node_os_upgrade_channel

  # Lets pods use Entra ID identities later (workload identity)
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # No shared admin certificate: every kubectl user signs in with Entra ID
  local_account_disabled = var.local_account_disabled

  azure_active_directory_role_based_access_control {
    tenant_id          = var.tenant_id
    azure_rbac_enabled = true
  }

  default_node_pool {
    name                        = var.default_node_pool.name
    vm_size                     = var.default_node_pool.vm_size
    node_count                  = var.default_node_pool.node_count
    os_disk_size_gb             = var.default_node_pool.os_disk_size_gb
    temporary_name_for_rotation = var.default_node_pool.temporary_name_for_rotation
    vnet_subnet_id              = var.subnet_id

    # Explicit values stop azurerm 4.x from showing a change on every plan
    upgrade_settings {
      max_surge                     = var.default_node_pool.max_surge
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = var.network_profile.pod_cidr
    service_cidr        = var.network_profile.service_cidr
    dns_service_ip      = var.network_profile.dns_service_ip
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_network_contributor" {
  scope                            = var.subnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_kubernetes_cluster.this.identity[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "cluster_admin" {
  for_each = toset(var.admin_principal_ids)

  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = each.value
}
