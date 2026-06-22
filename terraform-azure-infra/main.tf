locals {
  name_prefix = "${var.project}-${var.environment}"

  tags = merge({
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }, var.extra_tags)
}

module "resource_group" {
  source = "./modules/resource_group"

  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "./modules/network"

  name_prefix         = local.name_prefix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  vnet_address_space  = var.vnet_address_space
  subnet_prefixes     = var.subnet_prefixes
  tags                = local.tags
}

module "webapp" {
  source = "./modules/webapp"

  name_prefix         = local.name_prefix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku_name            = var.app_service_sku
  tags                = local.tags
}
