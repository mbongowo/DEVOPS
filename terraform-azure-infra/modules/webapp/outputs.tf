output "default_hostname" {
  description = "Default public hostname of the web app."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "name" {
  description = "Web app name."
  value       = azurerm_linux_web_app.this.name
}

output "service_plan_id" {
  description = "App Service Plan resource ID."
  value       = azurerm_service_plan.this.id
}
