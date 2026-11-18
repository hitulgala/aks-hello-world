# Inputs of the dev-centralindia stack. Values: terraform.tfvars (+ ids.auto.tfvars).

# ------------------------------------------------------------------ IDs (never in terraform.tfvars)
variable "tenant_id" {
  description = "Entra ID tenant ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.tenant_id))
    error_message = "tenant_id must be a GUID."
  }
}

variable "subscription_id" {
  description = "Subscription all resources are deployed to."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a GUID."
  }
}

variable "acr_push_principal_ids" {
  description = "Object IDs that may push images to the registry."
  type        = list(string)
  default     = []
}

variable "aks_admin_principal_ids" {
  description = "Object IDs that get cluster admin rights through Azure RBAC."
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------ Placement and tags
variable "location" {
  description = "Azure region for every resource in this stack."
  type        = string
}

variable "mandatory_tag_names" {
  description = "Tag names every resource must carry."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)

  validation {
    condition     = alltrue([for name in var.mandatory_tag_names : trimspace(lookup(var.tags, name, "")) != ""])
    error_message = "tags must contain a non-empty value for every name in mandatory_tag_names."
  }
}

# ------------------------------------------------------------------ Resources
variable "resource_group_name" {
  description = "Resource group for the project resources."
  type        = string
}

variable "network" {
  description = "Virtual network and subnets."
  type = object({
    vnet_name     = string
    address_space = list(string)
    subnets = map(object({
      name             = string
      address_prefixes = list(string)
    }))
  })
}

variable "container_registry" {
  description = "Azure Container Registry settings."
  type = object({
    name          = string
    sku           = optional(string, "Basic")
    admin_enabled = optional(bool, false)
  })
}

variable "aks" {
  description = "AKS cluster settings. subnet_key must be a key of network.subnets."
  type = object({
    name                      = string
    dns_prefix                = string
    node_resource_group_name  = string
    subnet_key                = string
    sku_tier                  = optional(string, "Free")
    kubernetes_version        = optional(string)
    automatic_upgrade_channel = optional(string, "patch")
    node_os_upgrade_channel   = optional(string, "NodeImage")
    local_account_disabled    = optional(bool, true)
    default_node_pool = object({
      name                        = string
      vm_size                     = string
      node_count                  = optional(number, 1)
      os_disk_size_gb             = optional(number, 30)
      temporary_name_for_rotation = string
      max_surge                   = optional(string, "10%")
    })
    network_profile = object({
      pod_cidr       = string
      service_cidr   = string
      dns_service_ip = string
    })
  })
}
