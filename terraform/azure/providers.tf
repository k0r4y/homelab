# providers.tf
# Defines which Terraform providers to use and their versions

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
 
  # Remote backend - stores terraform.tfstate in Azure Blob Storage
  # This means state is preserved even if mgmt01 is rebuilt
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "homelabtfstate2778"
    container_name       = "tfstate"
    key                  = "homelab.tfstate"
  }
}

provider "azurerm" {
  features {}
  # Authenticates using the Azure CLI login (az login)
  # In production this would use a Service Principal instead
  subscription_id = var.subscription_id
}
