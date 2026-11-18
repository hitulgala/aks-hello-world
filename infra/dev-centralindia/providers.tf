# The IDs come from ids.auto.tfvars locally, or TF_VAR_* variables in CI.
provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
