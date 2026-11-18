# ==============================================================================
# Stack   : dev-centralindia
# Purpose : Wires the modules together. No resource settings live here - every
#           name and setting comes from terraform.tfvars.
#
#   resource group -> network -> container-registry -> aks
# ==============================================================================

# A resource group is a single resource with nothing to encapsulate, so it is
# declared directly instead of being wrapped in a module.
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "network" {
  source = "../modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = var.network.vnet_name
  address_space       = var.network.address_space
  subnets             = var.network.subnets
  tags                = var.tags
}

module "container_registry" {
  source = "../modules/container-registry"

  name                = var.container_registry.name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.container_registry.sku
  admin_enabled       = var.container_registry.admin_enabled
  push_principal_ids  = var.acr_push_principal_ids
  tags                = var.tags
}

module "aks" {
  source = "../modules/aks"

  name                      = var.aks.name
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  dns_prefix                = var.aks.dns_prefix
  node_resource_group_name  = var.aks.node_resource_group_name
  sku_tier                  = var.aks.sku_tier
  kubernetes_version        = var.aks.kubernetes_version
  automatic_upgrade_channel = var.aks.automatic_upgrade_channel
  node_os_upgrade_channel   = var.aks.node_os_upgrade_channel
  local_account_disabled    = var.aks.local_account_disabled
  tenant_id                 = var.tenant_id
  subnet_id                 = module.network.subnet_ids[var.aks.subnet_key]
  default_node_pool         = var.aks.default_node_pool
  network_profile           = var.aks.network_profile
  acr_id                    = module.container_registry.id
  admin_principal_ids       = var.aks_admin_principal_ids
  tags                      = var.tags
}

