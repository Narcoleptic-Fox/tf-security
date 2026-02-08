variable "application_security_groups" {
  description = <<-EOT
    Map of Application Security Groups (ASGs) to create.
    ASGs logically group NICs for simplified NSG rules.
    
    Example:
    ```hcl
    application_security_groups = {
      web = {
        name                = "asg-web-prod-eus2"
        resource_group_name = "rg-network-prod"
        location            = "eastus2"
      }
      api = {
        name                = "asg-api-prod-eus2"
        resource_group_name = "rg-network-prod"
        location            = "eastus2"
      }
    }
    ```
  EOT
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "network_security_groups" {
  description = <<-EOT
    Map of Network Security Groups (NSGs) with their rules.
    
    Rules support:
    - Standard IP-based filtering (source/destination prefixes)
    - ASG-based filtering (reference ASG keys from application_security_groups)
    - Service Tags (VirtualNetwork, Internet, AzureLoadBalancer, etc.)
    
    Common service tags:
    - VirtualNetwork: All VNet address spaces
    - Internet: Public internet
    - AzureLoadBalancer: Azure load balancer health probes
    - Storage: Azure Storage IPs
    - Sql: Azure SQL IPs
    - AzureKeyVault: Key Vault IPs
    
    Example:
    ```hcl
    network_security_groups = {
      web = {
        name                = "nsg-web-prod-eus2"
        resource_group_name = "rg-network-prod"
        location            = "eastus2"
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
          deny_all_inbound = {
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
    ```
  EOT
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    tags                = optional(map(string), {})
    rules = optional(map(object({
      name                         = string
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = optional(string, "*")
      destination_port_range       = optional(string)
      source_port_ranges           = optional(list(string))
      destination_port_ranges      = optional(list(string))
      source_address_prefix        = optional(string)
      destination_address_prefix   = optional(string)
      source_address_prefixes      = optional(list(string))
      destination_address_prefixes = optional(list(string))
      source_asg_keys              = optional(list(string))
      destination_asg_keys         = optional(list(string))
      description                  = optional(string)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for nsg_key, nsg in var.network_security_groups :
      alltrue([
        for rule_key, rule in coalesce(nsg.rules, {}) :
        contains(["Inbound", "Outbound"], rule.direction)
      ])
    ])
    error_message = "Rule direction must be 'Inbound' or 'Outbound'."
  }

  validation {
    condition = alltrue([
      for nsg_key, nsg in var.network_security_groups :
      alltrue([
        for rule_key, rule in coalesce(nsg.rules, {}) :
        contains(["Allow", "Deny"], rule.access)
      ])
    ])
    error_message = "Rule access must be 'Allow' or 'Deny'."
  }

  validation {
    condition = alltrue([
      for nsg_key, nsg in var.network_security_groups :
      alltrue([
        for rule_key, rule in coalesce(nsg.rules, {}) :
        rule.priority >= 100 && rule.priority <= 4096
      ])
    ])
    error_message = "Rule priority must be between 100 and 4096."
  }
}

variable "nsg_subnet_associations" {
  description = <<-EOT
    Map of NSG-to-subnet associations.
    
    Example:
    ```hcl
    nsg_subnet_associations = {
      web_subnet = {
        subnet_id = azurerm_subnet.web.id
        nsg_key   = "web"  # References key in network_security_groups
      }
    }
    ```
  EOT
  type = map(object({
    subnet_id = string
    nsg_key   = string
  }))
  default = {}
}

variable "nsg_flow_logs" {
  description = <<-EOT
    Map of NSG Flow Log configurations for traffic analysis.
    
    Requires:
    - Network Watcher enabled in the region
    - Storage account for log storage
    - Optional: Log Analytics workspace for Traffic Analytics
    
    Example:
    ```hcl
    nsg_flow_logs = {
      web = {
        name                           = "flowlog-nsg-web"
        nsg_key                        = "web"
        network_watcher_name           = "NetworkWatcher_eastus2"
        network_watcher_resource_group = "NetworkWatcherRG"
        storage_account_id             = azurerm_storage_account.logs.id
        retention_days                 = 90
        traffic_analytics = {
          enabled               = true
          workspace_id          = azurerm_log_analytics_workspace.main.workspace_id
          workspace_region      = "eastus2"
          workspace_resource_id = azurerm_log_analytics_workspace.main.id
          interval_in_minutes   = 10
        }
      }
    }
    ```
  EOT
  type = map(object({
    name                           = string
    nsg_key                        = string
    network_watcher_name           = string
    network_watcher_resource_group = string
    storage_account_id             = string
    enabled                        = optional(bool, true)
    version                        = optional(number, 2)
    retention_enabled              = optional(bool, true)
    retention_days                 = optional(number, 90)
    tags                           = optional(map(string), {})
    traffic_analytics = optional(object({
      enabled               = bool
      workspace_id          = string
      workspace_region      = string
      workspace_resource_id = string
      interval_in_minutes   = optional(number, 10)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.nsg_flow_logs : v.retention_days >= 1 && v.retention_days <= 365
    ])
    error_message = "Retention days must be between 1 and 365."
  }

  validation {
    condition = alltrue([
      for k, v in var.nsg_flow_logs : contains([1, 2], v.version)
    ])
    error_message = "Flow log version must be 1 or 2."
  }
}

# Pre-built rule templates for common tiers
variable "tier_templates" {
  description = "Pre-built NSG rule templates for common application tiers"
  type = object({
    web_tier = optional(map(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string)
      source_address_prefix      = optional(string)
      destination_address_prefix = optional(string)
      description                = optional(string)
    })), {
      allow_http = {
        name                       = "AllowHTTP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "80"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        description                = "Allow HTTP from Internet"
      }
      allow_https = {
        name                       = "AllowHTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "443"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        description                = "Allow HTTPS from Internet"
      }
      allow_lb_probe = {
        name                       = "AllowAzureLBProbe"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        destination_port_range     = "*"
        source_address_prefix      = "AzureLoadBalancer"
        destination_address_prefix = "*"
        description                = "Allow Azure Load Balancer health probes"
      }
    })
    app_tier = optional(map(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string)
      source_address_prefix      = optional(string)
      destination_address_prefix = optional(string)
      description                = optional(string)
    })), {
      allow_from_web = {
        name                       = "AllowFromWebTier"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "8080"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
        description                = "Allow traffic from web tier"
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
        description                = "Allow Azure Load Balancer health probes"
      }
    })
    db_tier = optional(map(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string)
      source_address_prefix      = optional(string)
      destination_address_prefix = optional(string)
      description                = optional(string)
    })), {
      allow_sql_from_app = {
        name                       = "AllowSQLFromAppTier"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "1433"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
        description                = "Allow SQL from app tier"
      }
      deny_internet = {
        name                       = "DenyInternetInbound"
        priority                   = 4000
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        destination_port_range     = "*"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        description                = "Deny all internet inbound traffic"
      }
    })
  })
  default = {}
}
