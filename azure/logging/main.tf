/**
 * # Logging Module
 *
 * Provides Azure logging and monitoring foundation with:
 * - Log Analytics Workspaces
 * - Diagnostic Settings for resource logging
 * - Activity Log export to central workspace
 * - Sentinel integration support
 */

data "azurerm_subscription" "current" {}

# -----------------------------------------------------------------------------
# Log Analytics Workspaces
# Central logging destination for Azure Monitor
# -----------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "workspaces" {
  for_each = var.log_analytics_workspaces

  name                               = each.value.name
  resource_group_name                = each.value.resource_group_name
  location                           = each.value.location
  sku                                = each.value.sku
  retention_in_days                  = each.value.retention_in_days
  daily_quota_gb                     = each.value.daily_quota_gb
  internet_ingestion_enabled         = each.value.internet_ingestion_enabled
  internet_query_enabled             = each.value.internet_query_enabled
  reservation_capacity_in_gb_per_day = each.value.reservation_capacity_in_gb_per_day
  allow_resource_only_permissions    = each.value.allow_resource_only_permissions
  local_authentication_disabled      = each.value.local_authentication_disabled
  cmk_for_query_forced               = each.value.cmk_for_query_forced

  tags = each.value.tags
}

# -----------------------------------------------------------------------------
# Log Analytics Solutions
# Enable additional capabilities (e.g., Security, Updates)
# -----------------------------------------------------------------------------
resource "azurerm_log_analytics_solution" "solutions" {
  for_each = var.log_analytics_solutions

  solution_name         = each.value.solution_name
  location              = azurerm_log_analytics_workspace.workspaces[each.value.workspace_key].location
  resource_group_name   = azurerm_log_analytics_workspace.workspaces[each.value.workspace_key].resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.workspaces[each.value.workspace_key].id
  workspace_name        = azurerm_log_analytics_workspace.workspaces[each.value.workspace_key].name

  plan {
    publisher = each.value.publisher
    product   = each.value.product
  }

  tags = each.value.tags
}

# -----------------------------------------------------------------------------
# Diagnostic Settings
# Route resource logs to Log Analytics
# -----------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "settings" {
  for_each = var.diagnostic_settings

  name                           = each.value.name
  target_resource_id             = each.value.target_resource_id
  log_analytics_workspace_id     = each.value.workspace_key != null ? azurerm_log_analytics_workspace.workspaces[each.value.workspace_key].id : each.value.log_analytics_workspace_id
  log_analytics_destination_type = each.value.log_analytics_destination_type
  storage_account_id             = each.value.storage_account_id
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id
  eventhub_name                  = each.value.eventhub_name

  # Enable all log categories
  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  # Enable all log category groups (alternative to individual categories)
  dynamic "enabled_log" {
    for_each = each.value.log_category_groups
    content {
      category_group = enabled_log.value
    }
  }

  # Enable metrics
  dynamic "metric" {
    for_each = each.value.metrics
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}

# -----------------------------------------------------------------------------
# Activity Log Export
# Export subscription activity logs to Log Analytics
# -----------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  for_each = var.activity_log_exports

  name                       = each.value.name
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspaces[each.value.workspace_key].id

  # Activity Log categories
  dynamic "enabled_log" {
    for_each = each.value.categories
    content {
      category = enabled_log.value
    }
  }
}

# -----------------------------------------------------------------------------
# Action Groups
# Alert notification targets
# -----------------------------------------------------------------------------
resource "azurerm_monitor_action_group" "groups" {
  for_each = var.action_groups

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  short_name          = each.value.short_name
  enabled             = each.value.enabled

  dynamic "email_receiver" {
    for_each = each.value.email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  dynamic "sms_receiver" {
    for_each = each.value.sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "webhook_receiver" {
    for_each = each.value.webhook_receivers
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = webhook_receiver.value.use_common_alert_schema
    }
  }

  dynamic "azure_app_push_receiver" {
    for_each = each.value.azure_app_push_receivers
    content {
      name          = azure_app_push_receiver.value.name
      email_address = azure_app_push_receiver.value.email_address
    }
  }

  tags = each.value.tags
}

# -----------------------------------------------------------------------------
# Data Collection Rules (DCR)
# For Azure Monitor Agent data collection
# -----------------------------------------------------------------------------
resource "azurerm_monitor_data_collection_rule" "rules" {
  for_each = var.data_collection_rules

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  description         = each.value.description

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.workspaces[each.value.workspace_key].id
      name                  = each.value.destination_name
    }
  }

  dynamic "data_flow" {
    for_each = each.value.data_flows
    content {
      streams      = data_flow.value.streams
      destinations = data_flow.value.destinations
    }
  }

  dynamic "data_sources" {
    for_each = each.value.data_sources != null ? [each.value.data_sources] : []
    content {
      dynamic "syslog" {
        for_each = data_sources.value.syslog != null ? data_sources.value.syslog : []
        content {
          name           = syslog.value.name
          facility_names = syslog.value.facility_names
          log_levels     = syslog.value.log_levels
          streams        = syslog.value.streams
        }
      }

      dynamic "performance_counter" {
        for_each = data_sources.value.performance_counters != null ? data_sources.value.performance_counters : []
        content {
          name                          = performance_counter.value.name
          streams                       = performance_counter.value.streams
          sampling_frequency_in_seconds = performance_counter.value.sampling_frequency_in_seconds
          counter_specifiers            = performance_counter.value.counter_specifiers
        }
      }

      dynamic "windows_event_log" {
        for_each = data_sources.value.windows_event_logs != null ? data_sources.value.windows_event_logs : []
        content {
          name           = windows_event_log.value.name
          streams        = windows_event_log.value.streams
          x_path_queries = windows_event_log.value.x_path_queries
        }
      }
    }
  }

  tags = each.value.tags
}
