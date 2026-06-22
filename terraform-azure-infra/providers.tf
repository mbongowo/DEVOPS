provider "azurerm" {
  features {
    resource_group {
      # Let `terraform destroy` remove the RG even if drift left stray resources.
      prevent_deletion_if_contains_resources = false
    }
  }

  # Authentication is taken from the environment, in this order of preference:
  #   - `az login` context (local development), or
  #   - ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_TENANT_ID / ARM_SUBSCRIPTION_ID
  #     (service principal, used by CI).
  # Nothing secret is committed here.
}
