variable "name_prefix" {
  description = "Prefix for network resource names (e.g. project-environment)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create network resources in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "vnet_address_space" {
  description = "Virtual network address space."
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "Map of subnet name => CIDR."
  type        = map(string)
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)
  default     = {}
}
