# Inputs of the container-registry module.
variable "name" {
  description = "Registry name: 5-50 letters/digits, globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "Registry name must be 5-50 characters, letters and digits only."
  }
}

variable "resource_group_name" {
  description = "Existing resource group for the registry."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sku" {
  description = "Basic, Standard or Premium."
  type        = string

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable the shared admin account. Keep false; use RBAC instead."
  type        = bool
}

variable "push_principal_ids" {
  description = "Object IDs that receive AcrPush on the registry."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)
}
