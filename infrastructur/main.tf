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
  subscription_id = var.subscription_id
}

# ---------------------------------------------------
# Resource Group
# ---------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ---------------------------------------------------
# App Service Plan
# ---------------------------------------------------
resource "azurerm_service_plan" "appserviceplan" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# ---------------------------------------------------
# Linux Web App (MIT App Settings)
# ---------------------------------------------------
resource "azurerm_linux_web_app" "webapp" {
  name                = var.webapp_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.appserviceplan.id

  https_only = true

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT"  = "true"
    "WEBSITE_RUN_FROM_PACKAGE"        = "1"
    "AZURE_LANGUAGE_SERVICE_ENDPOINT" = azurerm_cognitive_account.language.endpoint
    "AZURE_LANGUAGE_SERVICE_KEY"      = azurerm_cognitive_account.language.primary_access_key
  }
}

# ---------------------------------------------------
# Virtual Network
# ---------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

# ---------------------------------------------------
# Subnet: Web App
# ---------------------------------------------------
resource "azurerm_subnet" "webapp_subnet" {
  name                 = var.webapp_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "appservice-delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

# ---------------------------------------------------
# Subnet: AI Service
# ---------------------------------------------------
resource "azurerm_subnet" "ai_subnet" {
  name                 = var.ai_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# ---------------------------------------------------
# Cognitive Language Service (Text Analytics)
# ---------------------------------------------------
resource "azurerm_cognitive_account" "language" {
  name                = var.cognitive_account_name
  location            = var.location
  resource_group_name = var.resource_group_name

  kind     = "TextAnalytics"
  sku_name = var.cognitive_sku

  # Required for Private Endpoint (globally unique)
  custom_subdomain_name = "${var.cognitive_account_name}-pe"

  public_network_access_enabled = true
}

# ---------------------------------------------------
# Private DNS Zone
# ---------------------------------------------------
resource "azurerm_private_dns_zone" "cognitive" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive_link" {
  name                  = "${var.vnet_name}-cognitive-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

# ---------------------------------------------------
# Private Endpoint (AI Service)
# ---------------------------------------------------
resource "azurerm_private_endpoint" "language_pe" {
  name                = "${var.cognitive_account_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.ai_subnet.id

  private_service_connection {
    name                           = "${var.cognitive_account_name}-pe-connection"
    private_connection_resource_id = azurerm_cognitive_account.language.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.cognitive.id
    ]
  }
}

# ---------------------------------------------------
# Web App → VNet Integration
# ---------------------------------------------------
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_web_app.webapp.id
  subnet_id      = azurerm_subnet.webapp_subnet.id
}
