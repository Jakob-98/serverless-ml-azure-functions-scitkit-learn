data "azurerm_resource_group" "serverless_ml" {
  name = var.resourcegroup_name
}

resource "azurerm_storage_account" "serverless_ml_functionapp" {
  name                     = "strg${replace(local.environment_id, "-", "")}"
  resource_group_name      = data.azurerm_resource_group.serverless_ml.name
  location                 = data.azurerm_resource_group.serverless_ml.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "serverless_ml_functionapp" {
  name                = "appplan-${local.environment_id}"
  resource_group_name = data.azurerm_resource_group.serverless_ml.name
  location            = data.azurerm_resource_group.serverless_ml.location
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = var.serverless_ml_functionapp_sku_tier
    size = var.serverless_ml_functionapp_sku_size
  }
}

resource "azurerm_application_insights" "serverless_ml_functionapp" {
  name                     = "appins-${local.environment_id}"
  resource_group_name      = data.azurerm_resource_group.serverless_ml.name
  location                 = data.azurerm_resource_group.serverless_ml.location
  daily_data_cap_in_gb     = 50
  sampling_percentage      = 100
  application_type         = "other"
}

resource "azurerm_function_app" "serverless_ml_functionapp" {
  name                       = "func-${local.environment_id}"
  resource_group_name        = data.azurerm_resource_group.serverless_ml.name
  location                   = data.azurerm_resource_group.serverless_ml.location
  app_service_plan_id        = azurerm_app_service_plan.serverless_ml_functionapp.id
  storage_account_name       = azurerm_storage_account.serverless_ml_functionapp.name
  storage_account_access_key = azurerm_storage_account.serverless_ml_functionapp.primary_access_key

  https_only = true
  version    = "~4"
  os_type    = "linux"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME              = "python"
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.serverless_ml_functionapp.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.serverless_ml_functionapp.connection_string
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
    linux_fx_version = "Python|3.9"
    ftps_state       = "Disabled"
  }
}

output "serverless_ml_functionapp_name" {
  value = azurerm_function_app.serverless_ml_functionapp.name
}
