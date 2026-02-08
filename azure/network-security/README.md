# Azure Network Security Module

Provides comprehensive Azure network security with Network Security Groups (NSGs), Application Security Groups (ASGs), and NSG Flow Logs for traffic analysis.

## Features

- **Network Security Groups** - Stateful firewall rules for subnets and NICs
- **Application Security Groups** - Logical grouping for simplified rule management
- **NSG Flow Logs** - Traffic analysis with optional Traffic Analytics
- **Tier Templates** - Pre-built rules for web, app, and database tiers

## Security Best Practices

1. **Default Deny** - Always include a low-priority deny rule
2. **Least Privilege** - Only allow required ports and sources
3. **Use Service Tags** - Prefer service tags over IP ranges for Azure services
4. **ASG-Based Rules** - Use ASGs for logical grouping instead of IP-based rules
5. **Flow Logs** - Enable for security auditing and troubleshooting

## Usage

### Basic NSG with Custom Rules

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

module "network_security" {
  source = "../../azure/network-security"
  
  network_security_groups = {
    web = {
      name                = "nsg-${module.naming.prefix}-web"
      resource_group_name = azurerm_resource_group.main.name
      location            = azurerm_resource_group.main.location
      tags                = module.tagging.azure_tags
      rules = {
        allow_https = {
          name                       = "AllowHTTPS"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        }
        allow_lb_probe = {
          name                       = "AllowAzureLBProbe"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "*"
          destination_port_range     = "*"
          source_address_prefix      = "AzureLoadBalancer"
          destination_address_prefix = "*"
        }
        deny_all = {
          name                       = "DenyAllInbound"
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }
  }
  
  nsg_subnet_associations = {
    web_subnet = {
      subnet_id = azurerm_subnet.web.id
      nsg_key   = "web"
    }
  }
}
```

### Multi-Tier with ASGs

```hcl
module "network_security" {
  source = "../../azure/network-security"
  
  # Create ASGs for logical grouping
  application_security_groups = {
    web = {
      name                = "asg-web-prod"
      resource_group_name = azurerm_resource_group.main.name
      location            = "eastus2"
      tags                = module.tagging.azure_tags
    }
    api = {
      name                = "asg-api-prod"
      resource_group_name = azurerm_resource_group.main.name
      location            = "eastus2"
      tags                = module.tagging.azure_tags
    }
    db = {
      name                = "asg-db-prod"
      resource_group_name = azurerm_resource_group.main.name
      location            = "eastus2"
      tags                = module.tagging.azure_tags
    }
  }
  
  network_security_groups = {
    # API tier NSG
    api = {
      name                = "nsg-api-prod"
      resource_group_name = azurerm_resource_group.main.name
      location            = "eastus2"
      tags                = module.tagging.azure_tags
      rules = {
        allow_from_web = {
          name                     = "AllowFromWeb"
          priority                 = 100
          direction                = "Inbound"
          access                   = "Allow"
          protocol                 = "Tcp"
          destination_port_range   = "8080"
          source_asg_keys          = ["web"]  # Use ASG instead of IP
          destination_asg_keys     = ["api"]
          description              = "Allow web tier to call API"
        }
        allow_to_db = {
          name                     = "AllowToDatabase"
          priority                 = 100
          direction                = "Outbound"
          access                   = "Allow"
          protocol                 = "Tcp"
          destination_port_range   = "1433"
          source_asg_keys          = ["api"]
          destination_asg_keys     = ["db"]
          description              = "Allow API to access database"
        }
      }
    }
  }
}

# Associate VMs with ASGs
resource "azurerm_network_interface_application_security_group_association" "web_vm" {
  network_interface_id          = azurerm_network_interface.web.id
  application_security_group_id = module.network_security.asg_ids["web"]
}
```

### NSG Flow Logs with Traffic Analytics

```hcl
module "network_security" {
  source = "../../azure/network-security"
  
  network_security_groups = {
    web = {
      name                = "nsg-web-prod"
      resource_group_name = azurerm_resource_group.main.name
      location            = "eastus2"
      rules               = { /* ... */ }
    }
  }
  
  nsg_flow_logs = {
    web = {
      name                           = "flowlog-nsg-web"
      nsg_key                        = "web"
      network_watcher_name           = "NetworkWatcher_eastus2"
      network_watcher_resource_group = "NetworkWatcherRG"
      storage_account_id             = azurerm_storage_account.logs.id
      retention_days                 = 90
      version                        = 2  # Use v2 for enhanced metrics
      
      traffic_analytics = {
        enabled               = true
        workspace_id          = azurerm_log_analytics_workspace.main.workspace_id
        workspace_region      = "eastus2"
        workspace_resource_id = azurerm_log_analytics_workspace.main.id
        interval_in_minutes   = 10
      }
    }
  }
}
```

## Tier Templates

Pre-built rule sets for common application tiers:

### Web Tier Rules
- Allow HTTP (80) from Internet
- Allow HTTPS (443) from Internet
- Allow Azure Load Balancer health probes

### App Tier Rules
- Allow traffic from VirtualNetwork on port 8080
- Allow Azure Load Balancer health probes

### Database Tier Rules
- Allow SQL (1433) from VirtualNetwork
- Deny all internet inbound

Use tier templates as a starting point:

```hcl
# Access default templates
output "web_rules" {
  value = module.network_security.tier_templates.web_tier
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
| application_security_groups | Map of ASGs to create | `map(object)` | `{}` | no |
| network_security_groups | Map of NSGs with rules | `map(object)` | `{}` | no |
| nsg_subnet_associations | Map of NSG-subnet associations | `map(object)` | `{}` | no |
| nsg_flow_logs | Map of NSG flow log configs | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| application_security_groups | Map of created ASGs |
| asg_ids | Map of ASG keys to resource IDs |
| network_security_groups | Map of created NSGs |
| nsg_ids | Map of NSG keys to resource IDs |
| security_rules | Map of created security rules |
| flow_logs | Map of created flow logs |

## Common Service Tags

| Service Tag | Description |
|------------|-------------|
| VirtualNetwork | All VNet address spaces + peered VNets |
| Internet | Public internet addresses |
| AzureLoadBalancer | Azure LB health probes (168.63.129.16) |
| Storage | Azure Storage service IPs |
| Sql | Azure SQL service IPs |
| AzureKeyVault | Key Vault service IPs |
| AzureActiveDirectory | Azure AD service IPs |
| AzureMonitor | Azure Monitor service IPs |

## Security Considerations

### Do

- ✅ Always include an explicit deny-all rule at lowest priority (4096)
- ✅ Use service tags instead of hardcoded IPs for Azure services
- ✅ Enable NSG flow logs for all production NSGs
- ✅ Use ASGs for dynamic workloads (auto-scaling, containers)
- ✅ Document rule purpose with descriptions

### Don't

- ❌ Don't allow SSH (22) or RDP (3389) from Internet
- ❌ Avoid overly permissive rules (e.g., allow all from VirtualNetwork)
- ❌ Don't use IP addresses for Azure services (they change)
- ❌ Don't disable flow logs in production

## License

MIT
