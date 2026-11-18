# ==============================================================================
# Module  : container-registry
# Purpose : Azure Container Registry with identity-based push access.
#
# The admin account (one shared username/password) stays disabled. Every
# identity that pushes images (you, later the CI pipeline) gets its own AcrPush
# role assignment. Pull access for AKS is granted in the aks module.
# ==============================================================================
resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  tags                = var.tags
}

resource "azurerm_role_assignment" "push" {
  for_each = toset(var.push_principal_ids)

  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = each.value
}
