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
}

provider "azurerm" {
  features {}
  # Authenticates using the Azure CLI login (az login)
  # In production this would use a Service Principal instead
  subscription_id = var.subscription_id
}
