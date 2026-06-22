# Remote state lives in Azure Blob Storage. It is left commented out so that
# `terraform init -backend=false` and `terraform validate` work out of the box
# (and so CI can validate without any cloud credentials).
#
# Bootstrapping order — the state storage account must exist BEFORE you point
# the backend at it, otherwise you have a chicken-and-egg problem:
#
#   az group create -n rg-tfstate -l westeurope
#   az storage account create -n sttfstate$RANDOM -g rg-tfstate \
#       --sku Standard_LRS --encryption-services blob
#   az storage container create -n tfstate --account-name <name>
#
# Then enable the block below and run:
#   terraform init -backend-config="storage_account_name=<name>"
#
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-tfstate"
#     storage_account_name = "" # supply via -backend-config
#     container_name       = "tfstate"
#     key                  = "infra.tfstate"
#   }
# }
