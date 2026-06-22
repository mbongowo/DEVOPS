# Web app names must be globally unique across all of Azure, so we append a
# short random suffix to the friendly prefix.
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

resource "azurerm_service_plan" "this" {
  name                = "asp-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = "app-${var.name_prefix}-${random_integer.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true
  tags                = var.tags

  site_config {
    # always_on is unsupported on the F1 free tier; the app idles out when not
    # in use, which is the expected trade-off for a zero-cost portfolio.
    always_on           = var.sku_name == "F1" ? false : true
    ftps_state          = "Disabled"
    http2_enabled       = true
    minimum_tls_version = "1.2"

    application_stack {
      node_version = "20-lts"
    }
  }

  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION = "~20"
  }
}
