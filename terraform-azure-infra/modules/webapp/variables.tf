variable "name_prefix" {
  description = "Prefix for web app resource names (e.g. project-environment)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the web app in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sku_name" {
  description = "App Service Plan SKU (F1 for free tier)."
  type        = string
  default     = "F1"
}

variable "tags" {
  description = "Tags applied to the web app resources."
  type        = map(string)
  default     = {}
}
