terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate25571"
    container_name       = "tfstate"
    key                  = "lazarus/dev.tfstate"
  }
}
