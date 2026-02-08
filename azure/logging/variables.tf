variable "log_analytics_workspaces" {
  description = <<-EOT
    Map of Log Analytics Workspaces to create.
    
    SKUs:
    - PerGB2018: Pay-per-use (recommended)
    - CapacityReservation: Committed tier for high volume
    
    Example:
    ```hcl
    log_analytics_workspaces = {
      main = {
        name                = "log-myapp-prod-eus2-001"
        resource_group_name = "rg-monitoring-prod"
        location            = "eastus2"
        sku                 = "PerGB2018"
        retention_in_days   = 90
      }
    }
    ```
  EOT
  type = map(object({
    name                               = string
    resource_group_name                = string
    location                           = string
    sku                                = optional(string, "PerGB2018")
    retention_in_days                  = optional(number, 30)
    daily_quota_gb                     = optional(number, -1) # -1 = no cap
    internet_ingestion_enabled         = optional(bool, true)
    internet_query_enabled             = optional(bool, true)
    reservation_capacity_in_gb_per_day = optional(number)
    allow_resource_only_permissions    = optional(bool, true)
    local_authentication_disabled      = optional(bool, false)
    cmk_for_query_forced               = optional(bool, false)
    tags                               = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.log_analytics_workspaces :
      contains(["Free", "PerNode", "Premium", "Standard", "Standalone", "Unlimited", "CapacityReservation", "PerGB2018"], v.sku)
    ])
    error_message = "Invalid SKU. Use PerGB2018 (recommended) or CapacityReservation."
  }

  validation {
    condition = alltrue([
      for k, v in var.log_analytics_workspaces :
      v.retention_in_days >= 30 && v.retention_in_days <= 730
    ])
    error_message = "Retention must be between 30 and 730 days."
  }
}

variable "log_analytics_solutions" {
  description = <<-EOT
    Map of Log Analytics Solutions to enable.
    
    Common solutions:
    - SecurityInsights: Microsoft Sentinel
    - Updates: Update Management
    - ChangeTracking: Change Tracking
    - Security: Security & Audit
    
    Example:
    ```hcl
    log_analytics_solutions = {
      sentinel = {
        workspace_key = "main"
        solution_name = "SecurityInsights"
        publisher     = "Microsoft"
        product       = "OMSGallery/SecurityInsights"
      }
    }
    ```
  EOT
  type = map(object({
    workspace_key = string
    solution_name = string
    publisher     = optional(string, "Microsoft")
    product       = string
    tags          = optional(map(string), {})
  }))
  default = {}
}

variable "diagnostic_settings" {
  description = <<-EOT
    Map of diagnostic settings for Azure resources.
    
    Routes logs and metrics to Log Analytics, Storage, or Event Hubs.
    
    Example:
    ```hcl
    diagnostic_settings = {
      keyvault = {
        name               = "diag-kv-myapp"
        target_resource_id = azurerm_key_vault.main.id
        workspace_key      = "main"
        log_category_groups = ["allLogs"]
        metrics = [{ category = "AllMetrics", enabled = true }]
      }
    }
    ```
  EOT
  type = map(object({
    name                           = string
    target_resource_id             = string
    workspace_key                  = optional(string) # Reference to workspace in this module
    log_analytics_workspace_id     = optional(string) # External workspace ID
    log_analytics_destination_type = optional(string) # "Dedicated" or "AzureDiagnostics"
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    log_categories                 = optional(list(string), [])
    log_category_groups            = optional(list(string), ["allLogs"])
    metrics = optional(list(object({
      category = string
      enabled  = optional(bool, true)
    })), [{ category = "AllMetrics", enabled = true }])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.diagnostic_settings :
      v.workspace_key != null || v.log_analytics_workspace_id != null || v.storage_account_id != null || v.eventhub_authorization_rule_id != null
    ])
    error_message = "At least one destination must be specified."
  }
}

variable "activity_log_exports" {
  description = <<-EOT
    Map of Activity Log export configurations.
    
    Exports subscription-level activity logs to Log Analytics.
    
    Categories:
    - Administrative: Resource management operations
    - Security: Security alerts and events
    - ServiceHealth: Azure service health events
    - Alert: Azure Monitor alerts
    - Recommendation: Azure Advisor recommendations
    - Policy: Azure Policy events
    - Autoscale: Autoscale events
    - ResourceHealth: Resource health events
    
    Example:
    ```hcl
    activity_log_exports = {
      all = {
        name          = "activity-log-export"
        workspace_key = "main"
        categories    = ["Administrative", "Security", "Policy", "Alert"]
      }
    }
    ```
  EOT
  type = map(object({
    name          = string
    workspace_key = string
    categories = optional(list(string), [
      "Administrative",
      "Security",
      "ServiceHealth",
      "Alert",
      "Recommendation",
      "Policy",
      "Autoscale",
      "ResourceHealth"
    ])
  }))
  default = {}
}

variable "action_groups" {
  description = <<-EOT
    Map of Action Groups for alert notifications.
    
    Example:
    ```hcl
    action_groups = {
      ops = {
        name                = "ag-ops-team"
        resource_group_name = "rg-monitoring"
        short_name          = "ops"
        email_receivers = [
          {
            name          = "ops-email"
            email_address = "ops@example.com"
          }
        ]
      }
    }
    ```
  EOT
  type = map(object({
    name                = string
    resource_group_name = string
    short_name          = string # Max 12 chars
    enabled             = optional(bool, true)
    email_receivers = optional(list(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = optional(bool, true)
    })), [])
    sms_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])
    webhook_receivers = optional(list(object({
      name                    = string
      service_uri             = string
      use_common_alert_schema = optional(bool, true)
    })), [])
    azure_app_push_receivers = optional(list(object({
      name          = string
      email_address = string
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.action_groups : length(v.short_name) <= 12
    ])
    error_message = "Action group short_name must be 12 characters or less."
  }
}

variable "data_collection_rules" {
  description = <<-EOT
    Map of Data Collection Rules for Azure Monitor Agent.
    
    Example:
    ```hcl
    data_collection_rules = {
      linux = {
        name                = "dcr-linux-prod"
        resource_group_name = "rg-monitoring"
        location            = "eastus2"
        workspace_key       = "main"
        destination_name    = "log-analytics"
        data_flows = [
          {
            streams      = ["Microsoft-Syslog"]
            destinations = ["log-analytics"]
          }
        ]
        data_sources = {
          syslog = [
            {
              name           = "syslog-datasource"
              facility_names = ["auth", "authpriv", "syslog"]
              log_levels     = ["Warning", "Error", "Critical", "Alert", "Emergency"]
              streams        = ["Microsoft-Syslog"]
            }
          ]
        }
      }
    }
    ```
  EOT
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    description         = optional(string)
    workspace_key       = string
    destination_name    = optional(string, "log-analytics")
    data_flows = list(object({
      streams      = list(string)
      destinations = list(string)
    }))
    data_sources = optional(object({
      syslog = optional(list(object({
        name           = string
        facility_names = list(string)
        log_levels     = list(string)
        streams        = list(string)
      })))
      performance_counters = optional(list(object({
        name                          = string
        streams                       = list(string)
        sampling_frequency_in_seconds = number
        counter_specifiers            = list(string)
      })))
      windows_event_logs = optional(list(object({
        name           = string
        streams        = list(string)
        x_path_queries = list(string)
      })))
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}
