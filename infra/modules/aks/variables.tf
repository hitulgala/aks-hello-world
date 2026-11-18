# Inputs of the aks module.
variable "name" {
  description = "Cluster name."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group for the cluster resource."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix of the cluster API server FQDN."
  type        = string
}

variable "node_resource_group_name" {
  description = "Name of the resource group AKS creates and manages for nodes, disks and load balancers. Must not exist yet."
  type        = string
}

variable "sku_tier" {
  description = "Free (no SLA), Standard or Premium."
  type        = string

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be Free, Standard or Premium."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version (e.g. \"1.31\"). null = the AKS default version."
  type        = string
  default     = null
}

variable "automatic_upgrade_channel" {
  description = "none, patch, stable, rapid or node-image."
  type        = string
}

variable "node_os_upgrade_channel" {
  description = "None, Unmanaged, SecurityPatch or NodeImage."
  type        = string
}

variable "local_account_disabled" {
  description = "Disable the local admin account so only Entra ID sign-in works."
  type        = bool
}

variable "tenant_id" {
  description = "Entra ID tenant used for cluster authentication."
  type        = string
}

variable "subnet_id" {
  description = "Subnet for the node pool."
  type        = string
}

variable "default_node_pool" {
  description = "System node pool settings."
  type = object({
    name                        = string
    vm_size                     = string
    node_count                  = number
    os_disk_size_gb             = number
    temporary_name_for_rotation = string
    max_surge                   = string
  })

  validation {
    condition = (
      can(regex("^[a-z][a-z0-9]{0,11}$", var.default_node_pool.name)) &&
      can(regex("^[a-z][a-z0-9]{0,11}$", var.default_node_pool.temporary_name_for_rotation))
    )
    error_message = "Node pool names must be 1-12 lowercase letters/digits, starting with a letter."
  }

  validation {
    condition     = var.default_node_pool.node_count >= 1
    error_message = "node_count must be at least 1."
  }
}

variable "network_profile" {
  description = "Overlay address ranges. Must not overlap the VNet or any peered network."
  type = object({
    pod_cidr       = string
    service_cidr   = string
    dns_service_ip = string
  })

  validation {
    condition = (
      can(cidrhost(var.network_profile.pod_cidr, 0)) &&
      can(cidrhost(var.network_profile.service_cidr, 0))
    )
    error_message = "pod_cidr and service_cidr must be valid CIDRs."
  }
}

variable "acr_id" {
  description = "Registry the kubelet identity gets AcrPull on."
  type        = string
}

variable "admin_principal_ids" {
  description = "Object IDs that receive 'Azure Kubernetes Service RBAC Cluster Admin'."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)
}
