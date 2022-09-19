terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.23.0"
    }
  }
  required_version = ">= 0.13"
}

provider "azurerm" {
  features {}
}