variable "project" {
  description = "Short project name used as a prefix for resource names (lowercase, no spaces)."
  type        = string
  default     = "petportal"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.project))
    error_message = "project must be 2-12 chars, lowercase letters/digits, starting with a letter."
  }
}

variable "environment" {
  description = "Deployment environment (drives naming and tags)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region. westeurope and eastus reliably offer the F1 free App Service tier."
  type        = string
  default     = "westeurope"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "subnet_prefixes" {
  description = "Map of subnet name => CIDR. Must sit within vnet_address_space."
  type        = map(string)
  default = {
    app = "10.20.1.0/24"
  }
}

variable "app_service_sku" {
  description = "App Service Plan SKU. Pinned to the free tier for a zero-cost portfolio."
  type        = string
  default     = "F1"

  validation {
    # Guardrail: keep this repo on the free tier. Bump deliberately if you ever
    # need VNet integration or always_on (both require B1+).
    condition     = contains(["F1", "B1"], var.app_service_sku)
    error_message = "app_service_sku must be F1 (free) or B1 (cheapest paid). Other SKUs are blocked to avoid surprise costs."
  }
}

variable "extra_tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}
