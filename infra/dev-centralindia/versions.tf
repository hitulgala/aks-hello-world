# Terraform and provider versions for this stack. The backend values are
# supplied at init time: terraform init -backend-config="backend.hcl"
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {}
}
