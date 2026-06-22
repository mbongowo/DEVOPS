project         = "petportal"
environment     = "dev"
location        = "westeurope"
app_service_sku = "F1"

vnet_address_space = ["10.20.0.0/16"]
subnet_prefixes = {
  app = "10.20.1.0/24"
}
