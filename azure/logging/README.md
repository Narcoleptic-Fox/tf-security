# Azure Logging Module

Provides comprehensive Azure logging and monitoring with Log Analytics Workspaces, diagnostic settings, Activity Log export, and Azure Monitor Agent support.

## Features

- **Log Analytics Workspaces** - Central logging destination
- **Diagnostic Settings** - Route resource logs to Log Analytics
- **Activity Log Export** - Subscription-level audit logging
- **Action Groups** - Alert notification configuration
- **Data Collection Rules** - Azure Monitor Agent configuration
- **Sentinel Integration** - Enable SecurityInsights solution

## Security Best Practices

1. **Centralized Logging** - Route all logs to a dedicated Log Analytics Workspace
2. **Activity Log Export** - Always export subscription activity logs
3. **Retention Policies** - Set appropriate retention for compliance
4. **Access Control** - Use RBAC for workspace access
5. **CMK Encryption** - Enable for sensitive workloads

## Usage

### Basic Log Analytics Workspace

```hcl
module "naming" {
  source = "../../core/naming"
  
  project     = "myapp"
  environment = "prod"
  region      = "eastus2"
}

module "tagging" {
  source = "../../core/tagging"
  
  project     = "myapp"
  environment = "prod"
  owner       = "platform-team"
  cost_center = "engineering"
}

module "logging" {
  source = "../../azure/logging"
  
  log_analytics_workspaces = {
    main = {
      name                = "log-${module.naming.prefix}-001"
      resource_group_name = azurerm_resource_group.main.name
      location            = azurerm_resource_group.main.location
      sku                 = "PerGB2018"
      retention_in_days   = 90
      tags                = module.tagging.azure_tags
    }
  }
  
  # Export activity logs
  activity_log_exports = {
    all = {
      name          = "activity-log-export"
      workspace_key = "main"
      categories = [
        "Administrative",
        "Security",
        "Policy",
        "Alert",
        "ServiceHealth"
      ]
    }
  }
}
```

### Diagnostic Settings for Resources

```hcl
module "logging" {
  source = "../../azure/logging"
  
  log_analytics_workspaces = {
    main = {
      name                = "log-central-prod"
      resource_group_name = azurerm_resource_group.main.name
      location            = "eastus2"
      retention_in_days   = 90
    }
  }
  
  diagnostic_settings = {
    keyvault = {
      name               = "diag-kv-myapp"
      target_resource_id = azurerm_key_vault.main.id
      workspace_key      = "main"
      log_category_groups = ["allLogs"]  # Capture all logs
      metrics = [
        { category = "AllMetrics", enabled = true }
      ]
    }
    storage = {
      name               = "diag-storage-myapp"
      target_resource_id = "${azurerm_storage_account.main.id}/blobServices/default"
      workspace_key      = "main"
      log_categories     = ["StorageRead", "StorageWrite", "StorageDelete"]
      metrics = [
        { category = "Transaction", enabled = true }
      ]
    }
    sql = {
      name               = "diag-sql-myapp"
      target_resource_id = azurerm_mssql_database.main.id
      workspace_key      = "main"
      log_category_groups = ["allLogs"]
    }
  }
}
```

### Microsoft Sentinel Integration

```hcl
module "logging" {
  source = "../../azure/logging"
  
  log_analytics_workspaces = {
    sentinel = {
      name                = "log-sentinel-prod"
      resource_group_name = azurerm_resource_group.security.name
      location            = "eastus2"
      retention_in_days   = 90
    }
  }
  
  log_analytics_solutions = {
    sentinel = {
      workspace_key = "sentinel"
      solution_name = "SecurityInsights"
      publisher     = "Microsoft"
      product       = "OMSGallery/SecurityInsights"
    }
  }
  
  activity_log_exports = {
    security = {
      name          = "activity-log-sentinel"
      workspace_key = "sentinel"
      categories    = ["Security", "Administrative", "Policy"]
    }
  }
}
```

### Action Groups for Alerts

```hcl
module "logging" {
  source = "../../azure/logging"
  
  action_groups = {
    ops_team = {
      name                = "ag-ops-team"
      resource_group_name = azurerm_resource_group.main.name
      short_name          = "ops"
      email_receivers = [
        {
          name          = "ops-lead"
          email_address = "ops-lead@example.com"
        },
        {
          name          = "on-call"
          email_address = "oncall@example.com"
        }
      ]
      webhook_receivers = [
        {
          name        = "slack-alerts"
          service_uri = var.slack_webhook_url
        }
      ]
    }
    security_team = {
      name                = "ag-security-team"
      resource_group_name = azurerm_resource_group.main.name
      short_name          = "security"
      email_receivers = [
        {
          name          = "security-team"
          email_address = "security@example.com"
        }
      ]
    }
  }
}
```

### Data Collection Rules for VMs

```hcl
module "logging" {
  source = "../../azure/logging"
  
  log_analytics_workspaces = {
    main = {
      name                = "log-infra-prod"
      resource_group_name = azurerm_resource_group.main.name
      location            = "eastus2"
    }
  }
  
  data_collection_rules = {
    linux_security = {
      name                = "dcr-linux-security"
      resource_group_name = azurerm_resource_group.main.name
      location            = "eastus2"
      workspace_key       = "main"
      description         = "Security logs from Linux VMs"
      
      data_flows = [
        {
          streams      = ["Microsoft-Syslog"]
          destinations = ["log-analytics"]
        }
      ]
      
      data_sources = {
        syslog = [
          {
            name           = "auth-logs"
            facility_names = ["auth", "authpriv"]
            log_levels     = ["Warning", "Error", "Critical", "Alert", "Emergency"]
            streams        = ["Microsoft-Syslog"]
          },
          {
            name           = "security-logs"
            facility_names = ["syslog", "daemon"]
            log_levels     = ["Error", "Critical", "Alert", "Emergency"]
            streams        = ["Microsoft-Syslog"]
          }
        ]
      }
    }
    
    windows_security = {
      name                = "dcr-windows-security"
      resource_group_name = azurerm_resource_group.main.name
      location            = "eastus2"
      workspace_key       = "main"
      description         = "Security logs from Windows VMs"
      
      data_flows = [
        {
          streams      = ["Microsoft-Event"]
          destinations = ["log-analytics"]
        }
      ]
      
      data_sources = {
        windows_event_logs = [
          {
            name    = "security-events"
            streams = ["Microsoft-Event"]
            x_path_queries = [
              "Security!*[System[(Level=1 or Level=2 or Level=3)]]",
              "System!*[System[(Level=1 or Level=2 or Level=3)]]"
            ]
          }
        ]
      }
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| log_analytics_workspaces | Map of Log Analytics Workspaces | `map(object)` | `{}` | no |
| log_analytics_solutions | Map of solutions to enable | `map(object)` | `{}` | no |
| diagnostic_settings | Map of diagnostic settings | `map(object)` | `{}` | no |
| activity_log_exports | Map of activity log exports | `map(object)` | `{}` | no |
| action_groups | Map of action groups | `map(object)` | `{}` | no |
| data_collection_rules | Map of DCRs for AMA | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| workspaces | Map of created workspaces |
| workspace_ids | Map of workspace keys to resource IDs |
| workspace_customer_ids | Map of workspace keys to customer IDs |
| diagnostic_settings | Map of created diagnostic settings |
| action_group_ids | Map of action group keys to resource IDs |
| data_collection_rule_ids | Map of DCR keys to resource IDs |

## Activity Log Categories

| Category | Description |
|----------|-------------|
| Administrative | Resource management operations |
| Security | Security alerts and events |
| ServiceHealth | Azure service health events |
| Alert | Azure Monitor alerts |
| Recommendation | Azure Advisor recommendations |
| Policy | Azure Policy events |
| Autoscale | Autoscale operations |
| ResourceHealth | Resource health changes |

## Security Considerations

### Do

- ✅ Export activity logs from all subscriptions
- ✅ Set retention to meet compliance requirements
- ✅ Enable diagnostic settings for all critical resources
- ✅ Use action groups for security alert notifications
- ✅ Enable Sentinel for security monitoring

### Don't

- ❌ Don't disable activity log export
- ❌ Don't set retention below compliance requirements
- ❌ Avoid overly permissive workspace access
- ❌ Don't ignore Log Analytics costs (set daily caps if needed)

## License

MIT
