terraform {
  required_version = ">= 1.2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  # Deine Subscription hier eintragen:
  subscription_id = "d03ace1e-ea95-41e6-be4c-125de5af139d"
}

# ---------------------------
# Resource Group
# ---------------------------
resource "azurerm_resource_group" "rg" {
  name     = "clco-demo-rg"
  location = "norwayeast"
}

# ---------------------------
# App Service Plan
# ---------------------------
resource "azurerm_service_plan" "appserviceplan" {
  name                = "clco-demo-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  os_type  = "Linux"
  sku_name = "B1"
}

# ---------------------------
# Web App
# ---------------------------
resource "azurerm_linux_web_app" "webapp" {
  name                = "clco-demo-webapp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.appserviceplan.id

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "WEBSITE_RUN_FROM_PACKAGE"       = "1"
  }
}
