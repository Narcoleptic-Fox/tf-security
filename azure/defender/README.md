# Azure Defender Module

Provides Microsoft Defender for Cloud configuration including plan enablement, security contacts, auto-provisioning, and compliance policy assignments.

## Features

- **Defender Plans** - Enable protection for VMs, Storage, SQL, Containers, etc.
- **Security Contacts** - Configure alert notifications
- **Auto-Provisioning** - Automatic agent deployment
- **Storage Defender** - Per-account malware scanning and data discovery
- **Compliance Policies** - Azure Security Benchmark, CIS, NIST, ISO 27001

## Security Best Practices

1. **Enable Defender for All Critical Resources** - At minimum: VMs, Storage, Containers, Key Vault
2. **Configure Security Contacts** - Ensure alerts reach the right people
3. **Enable Auto-Provisioning** - Ensure consistent agent deployment
4. **Apply Security Benchmark** - Use Azure Security Benchmark as baseline
5. **Review Recommendations** - Regularly review and address security recommendations

## Usage

### Basic Defender Configuration

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

module "defender" {
  source = "../../azure/defender"
  
  # Enable Defender for key resource types
  defender_plans = {
    vms = {
      resource_type = "VirtualMachines"
      tier          = "Standard"
      subplan       = "P2"  # Full protection
    }
    storage = {
      resource_type = "StorageAccounts"
      tier          = "Standard"
      subplan       = "DefenderForStorageV2"
    }
    containers = {
      resource_type = "Containers"
      tier          = "Standard"
    }
    keyvaults = {
      resource_type = "KeyVaults"
      tier          = "Standard"
    }
    sql = {
      resource_type = "SqlServers"
      tier          = "Standard"
    }
    arm = {
      resource_type = "Arm"
      tier          = "Standard"
    }
  }
  
  # Security alert notifications
  security_contacts = {
    primary = {
      email               = "security@example.com"
      phone               = "+1-555-123-4567"
      alert_notifications = true
      alerts_to_admins    = true
    }
  }
}
```

### Full Enterprise Configuration

```hcl
module "defender" {
  source = "../../azure/defender"
  
  # Enable comprehensive protection
  defender_plans = {
    vms = {
      resource_type = "VirtualMachines"
      tier          = "Standard"
      subplan       = "P2"
    }
    storage = {
      resource_type = "StorageAccounts"
      tier          = "Standard"
      subplan       = "DefenderForStorageV2"
      extensions = [
        {
          name = "OnUploadMalwareScanning"
          additional_properties = {
            CapGBPerMonthPerStorageAccount = "5000"
          }
        },
        {
          name = "SensitiveDataDiscovery"
          additional_properties = {
            isEnabled = "true"
          }
        }
      ]
    }
    containers = {
      resource_type = "Containers"
      tier          = "Standard"
    }
    keyvaults = {
      resource_type = "KeyVaults"
      tier          = "Standard"
    }
    sql = {
      resource_type = "SqlServers"
      tier          = "Standard"
    }
    sql_vms = {
      resource_type = "SqlServerVirtualMachines"
      tier          = "Standard"
    }
    app_services = {
      resource_type = "AppServices"
      tier          = "Standard"
    }
    arm = {
      resource_type = "Arm"
      tier          = "Standard"
    }
    dns = {
      resource_type = "Dns"
      tier          = "Standard"
    }
    cosmos = {
      resource_type = "CosmosDbs"
      tier          = "Standard"
    }
    oss_dbs = {
      resource_type = "OpenSourceRelationalDatabases"
      tier          = "Standard"
    }
    api = {
      resource_type = "Api"
      tier          = "Standard"
    }
  }
  
  # Multiple security contacts
  security_contacts = {
    security_team = {
      name                = "security-team"
      email               = "security-team@example.com"
      alert_notifications = true
      alerts_to_admins    = true
    }
    on_call = {
      name                = "on-call"
      email               = "oncall@example.com"
      phone               = "+1-555-999-8888"
      alert_notifications = true
      alerts_to_admins    = false
    }
  }
  
  # Send data to Log Analytics
  workspace_settings = {
    main = {
      workspace_id = module.logging.workspace_ids["security"]
    }
  }
  
  # Apply Azure Security Benchmark
  security_policy_assignments = {
    azure_security_benchmark = {
      name                 = "azure-security-benchmark"
      policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
      display_name         = "Azure Security Benchmark"
      description          = "Baseline security controls"
      location             = "eastus2"
      managed_identity     = true
    }
    cis_benchmark = {
      name                 = "cis-azure-1-4"
      policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/c3f5c4d9-9a1d-4a99-85c0-7f93e384d5c5"
      display_name         = "CIS Microsoft Azure Foundations Benchmark v1.4.0"
      location             = "eastus2"
      managed_identity     = true
    }
  }
}
```

### Per-Storage Account Configuration

```hcl
module "defender" {
  source = "../../azure/defender"
  
  defender_plans = {
    storage = {
      resource_type = "StorageAccounts"
      tier          = "Standard"
      subplan       = "DefenderForStorageV2"
    }
  }
  
  # Override settings for specific storage accounts
  storage_defender_settings = {
    sensitive_data = {
      storage_account_id               = azurerm_storage_account.sensitive.id
      override_subscription_settings   = true
      malware_scanning_enabled         = true
      malware_scanning_cap_gb          = 10000  # Higher cap for sensitive data
      sensitive_data_discovery_enabled = true
    }
    public_assets = {
      storage_account_id               = azurerm_storage_account.public.id
      override_subscription_settings   = true
      malware_scanning_enabled         = true
      malware_scanning_cap_gb          = 500  # Lower cap for public assets
      sensitive_data_discovery_enabled = false
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
| defender_plans | Map of Defender plans to enable | `map(object)` | `{}` | no |
| security_contacts | Map of security contacts | `map(object)` | `{}` | no |
| auto_provisioning_settings | Map of auto-provisioning settings | `map(object)` | `{}` | no |
| workspace_settings | Map of workspace configurations | `map(object)` | `{}` | no |
| storage_defender_settings | Map of per-storage Defender settings | `map(object)` | `{}` | no |
| security_policy_assignments | Map of policy assignments | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| defender_plans | Map of enabled Defender plans |
| enabled_plans | List of enabled plan resource types |
| security_contacts | Map of configured contacts |
| security_policy_assignments | Map of policy assignments |
| policy_set_ids | Common policy set IDs for reference |

## Defender Plans

| Resource Type | Description |
|---------------|-------------|
| VirtualMachines | Servers and VMs (P1: basic, P2: full) |
| SqlServers | Azure SQL Database |
| StorageAccounts | Azure Storage |
| Containers | AKS and container registries |
| KeyVaults | Azure Key Vault |
| AppServices | Azure App Service |
| Dns | Azure DNS |
| Arm | Azure Resource Manager operations |
| CosmosDbs | Azure Cosmos DB |
| OpenSourceRelationalDatabases | PostgreSQL, MySQL, MariaDB |
| SqlServerVirtualMachines | SQL Server on VMs |
| Api | API Management |

## Compliance Frameworks

Available policy sets (use `policy_set_ids` output):
- Azure Security Benchmark
- CIS Microsoft Azure Foundations Benchmark v1.4.0
- NIST SP 800-53 Rev. 5
- ISO 27001
- PCI DSS v4.0
- HIPAA

## Security Considerations

### Do

- ✅ Enable Defender for all production subscriptions
- ✅ Enable at least: VMs, Storage, Containers, Key Vault, ARM
- ✅ Configure security contacts with valid email addresses
- ✅ Review and address security recommendations regularly
- ✅ Apply Azure Security Benchmark as baseline

### Don't

- ❌ Don't disable Defender in production
- ❌ Don't ignore high-severity recommendations
- ❌ Don't use Free tier for production workloads
- ❌ Avoid leaving security contacts unconfigured

## Estimated Costs

Defender costs vary by resource type and volume. Key pricing:
- VMs: ~$15/VM/month (P2)
- Storage: ~$10/storage account/month + scanning fees
- Containers: ~$7/vCore/month
- Key Vault: ~$0.02/10,000 transactions

Check [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) for current rates.

## License

MIT
