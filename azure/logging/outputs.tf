# Log Analytics Workspace outputs
output "workspaces" {
  description = "Map of created Log Analytics Workspaces"
  value = {
    for k, v in azurerm_log_analytics_workspace.workspaces : k => {
      id           = v.id
      name         = v.name
      workspace_id = v.workspace_id
      location     = v.location
    }
  }
}

output "workspace_ids" {
  description = "Map of workspace keys to resource IDs"
  value       = { for k, v in azurerm_log_analytics_workspace.workspaces : k => v.id }
}

output "workspace_customer_ids" {
  description = "Map of workspace keys to customer IDs (workspace_id)"
  value       = { for k, v in azurerm_log_analytics_workspace.workspaces : k => v.workspace_id }
}

output "workspace_primary_shared_keys" {
  description = "Map of workspace keys to primary shared keys (sensitive)"
  value       = { for k, v in azurerm_log_analytics_workspace.workspaces : k => v.primary_shared_key }
  sensitive   = true
}

# Log Analytics Solutions outputs
output "solutions" {
  description = "Map of created Log Analytics Solutions"
  value = {
    for k, v in azurerm_log_analytics_solution.solutions : k => {
      id            = v.id
      solution_name = v.solution_name
    }
  }
}

# Diagnostic Settings outputs
output "diagnostic_settings" {
  description = "Map of created diagnostic settings"
  value = {
    for k, v in azurerm_monitor_diagnostic_setting.settings : k => {
      id                 = v.id
      name               = v.name
      target_resource_id = v.target_resource_id
    }
  }
}

# Activity Log Export outputs
output "activity_log_exports" {
  description = "Map of created activity log export settings"
  value = {
    for k, v in azurerm_monitor_diagnostic_setting.activity_log : k => {
      id   = v.id
      name = v.name
    }
  }
}

# Action Group outputs
output "action_groups" {
  description = "Map of created action groups"
  value = {
    for k, v in azurerm_monitor_action_group.groups : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "action_group_ids" {
  description = "Map of action group keys to resource IDs"
  value       = { for k, v in azurerm_monitor_action_group.groups : k => v.id }
}

# Data Collection Rule outputs
output "data_collection_rules" {
  description = "Map of created data collection rules"
  value = {
    for k, v in azurerm_monitor_data_collection_rule.rules : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "data_collection_rule_ids" {
  description = "Map of DCR keys to resource IDs"
  value       = { for k, v in azurerm_monitor_data_collection_rule.rules : k => v.id }
}

# Subscription context
output "subscription_id" {
  description = "Current subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}
