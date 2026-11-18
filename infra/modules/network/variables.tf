# Inputs of the network module.
variable "resource_group_name" {
  description = "Existing resource group for the network."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name."
  type        = string
}

variable "address_space" {
  description = "Address space(s) of the virtual network."
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "Every address_space entry must be a valid CIDR, e.g. 10.20.0.0/16."
  }
}

variable "subnets" {
  description = "Subnets keyed by logical name: { key = { name, address_prefixes } }."
  type = map(object({
    name             = string
    address_prefixes = list(string)
  }))
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)
}
