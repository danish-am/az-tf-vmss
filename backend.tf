terraform {
  backend "azurerm" {
    resource_group_name   = "terraform-backend-rg"
    storage_account_name  = "tfbackenddanish123"
    container_name        = "tfstate"  
    key                   = "vmssapp.terraform.tfstate"
  }
}
