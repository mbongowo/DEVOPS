project     = "petportal"
environment = "prod"
location    = "westeurope"

# Still F1 to stay free. Bump to B1 only if you need always_on / VNet
# integration — the variable validation in variables.tf blocks anything pricier.
app_service_sku = "F1"

vnet_address_space = ["10.30.0.0/16"]
subnet_prefixes = {
  app = "10.30.1.0/24"
}
