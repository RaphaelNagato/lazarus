data "azurerm_resource_group" "rg-lazarus-dev" {
  name = "rg-lazarus-dev"
}

resource "azurerm_log_analytics_workspace" "laz-dev-law" {
  name                = "${var.prefix}-dev-law"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg-lazarus-dev.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 1
  tags                = var.tags
}

resource "azurerm_application_insights" "laz-dev-app-insights" {
  name                = "${var.prefix}-dev-app-insights"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg-lazarus-dev.name
  workspace_id        = azurerm_log_analytics_workspace.laz-dev-law.id
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_service_plan" "laz-dev-service-plan" {
  name                = "${var.prefix}-dev-service-plan"
  resource_group_name = data.azurerm_resource_group.rg-lazarus-dev.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "laz-dev-web-app" {
  name                = "${var.prefix}-dev-web-app"
  resource_group_name = data.azurerm_resource_group.rg-lazarus-dev.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.laz-dev-service-plan.id
  https_only          = true
  tags                = var.tags

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    http_logs {
      file_system {
        retention_in_days = 2
        retention_in_mb   = 35
      }
    }
  }

  site_config {
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    health_check_path                 = "/healthz"
    health_check_eviction_time_in_min = 2
    application_stack {
      dotnet_version = "10.0"
    }

  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.laz-dev-app-insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.laz-dev-app-insights.connection_string
  }


  identity {
    type = "SystemAssigned"
  }

  sticky_settings {
    app_setting_names = ["FAIL_MODE"]
  }
}

resource "azurerm_linux_web_app_slot" "laz-dev-web-app-staging-slot" {
  name           = "${var.prefix}-dev-web-app-staging-slot"
  app_service_id = azurerm_linux_web_app.laz-dev-web-app.id
  https_only     = true

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    http_logs {
      file_system {
        retention_in_days = 2
        retention_in_mb   = 35
      }
    }
  }

  site_config {
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    health_check_path                 = "/healthz"
    health_check_eviction_time_in_min = 2
    application_stack {
      dotnet_version = "10.0"
    }
  }

  # Non-sticky app settings swap with the slot, so these must match the main app.
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.laz-dev-app-insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.laz-dev-app-insights.connection_string
  }
}

resource "azurerm_monitor_diagnostic_setting" "laz-dev-web-app-diag" {
  name                       = "${var.prefix}-dev-web-app-diag"
  target_resource_id         = azurerm_linux_web_app.laz-dev-web-app.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.laz-dev-law.id

  dynamic "enabled_log" {
    for_each = local.web_app_log_categories
    content {
      category = enabled_log.value
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "laz-dev-web-app-staging-slot-diag" {
  name                       = "${var.prefix}-dev-web-app-staging-slot-diag"
  target_resource_id         = azurerm_linux_web_app_slot.laz-dev-web-app-staging-slot.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.laz-dev-law.id

  dynamic "enabled_log" {
    for_each = local.web_app_log_categories
    content {
      category = enabled_log.value
    }
  }
}
