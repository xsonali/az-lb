# DO NOT put this file to GitHub - Non production Environment
terraform {
  backend "azurerm" {
    resource_group_name  = "backend-rg"
    storage_account_name = "backendstorage747"
    container_name       = "ptstate"
    key                  = "tfstate"
  }
}
  
