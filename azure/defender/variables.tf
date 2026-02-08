variable "defender_plans" {
  description = <<-EOT
    Map of Defender for Cloud plans to enable.
    
    Resource types:
    - VirtualMachines: Servers and VMs
    - SqlServers: Azure SQL
    - AppServices: App Service
    - StorageAccounts: Azure Storage
    - Containers: AKS and container registries
    - KeyVaults: Key Vault
    - Dns: Azure DNS
    - Arm: Azure Resource Manager
    - OpenSourceRelationalDatabases: PostgreSQL, MySQL, MariaDB
    - CosmosDbs: Cosmos DB
    - SqlServerVirtualMachines: SQL on VMs
    - Api: API Management
    
    Tiers:
    - Free: Basic security features
    - Standard: Full Defender capabilities
    
    Example:
    ```hcl
    defender_plans = {
      vms = {
        resource_type = "VirtualMachines"
        tier          = "Standard"
        subplan       = "P2"  # P1 or P2 for VMs
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
    }
    ```
  EOT
  type = map(object({
    resource_type = string
    tier          = optional(string, "Standard")
    subplan       = optional(string)
    extensions = optional(list(object({
      name                  = string
      additional_properties = optional(map(string), {})
    })))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.defender_plans : contains(["Free", "Standard"], v.tier)
    ])
    error_message = "Tier must be 'Free' or 'Standard'."
  }

  validation {
    condition = alltrue([
      for k, v in var.defender_plans : contains([
        "VirtualMachines",
        "SqlServers",
        "AppServices",
        "StorageAccounts",
        "Containers",
        "KeyVaults",
        "Dns",
        "Arm",
        "OpenSourceRelationalDatabases",
        "CosmosDbs",
        "SqlServerVirtualMachines",
        "Api",
        "CloudPosture"
      ], v.resource_type)
    ])
    error_message = "Invalid resource_type."
  }
}

variable "security_contacts" {
  description = <<-EOT
    Map of security contacts for alert notifications.
    
    Example:
    ```hcl
    security_contacts = {
      primary = {
        name                = "primary"
        email               = "security@example.com"
        phone               = "+1-555-123-4567"
        alert_notifications = true
        alerts_to_admins    = true
      }
    }
    ```
  EOT
  type = map(object({
    name                = optional(string, "default")
    email               = string
    phone               = optional(string)
    alert_notifications = optional(bool, true)
    alerts_to_admins    = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.security_contacts :
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", v.email))
    ])
    error_message = "Invalid email address format."
  }
}

variable "auto_provisioning_settings" {
  description = <<-EOT
    Map of auto-provisioning settings.
    
    Auto-provisioning automatically deploys monitoring agents to resources.
    
    Types:
    - LogAnalyticsAgent: Legacy Log Analytics agent (deprecated)
    - VulnerabilityAssessment: Qualys or built-in VA
    
    Example:
    ```hcl
    auto_provisioning_settings = {
      log_analytics = {
        type    = "LogAnalyticsAgentForVMs"
        enabled = true
      }
    }
    ```
  EOT
  type = map(object({
    enabled = bool
  }))
  default = {}
}

variable "workspace_settings" {
  description = <<-EOT
    Map of Log Analytics workspace configurations for Defender.
    
    Defines where Defender for Cloud sends data.
    
    Example:
    ```hcl
    workspace_settings = {
      default = {
        workspace_id = azurerm_log_analytics_workspace.security.id
      }
    }
    ```
  EOT
  type = map(object({
    workspace_id = string
    scope        = optional(string) # Defaults to subscription
  }))
  default = {}
}

variable "server_vulnerability_assessment" {
  description = <<-EOT
    Map of server vulnerability assessment configurations for hybrid machines.
    
    Example:
    ```hcl
    server_vulnerability_assessment = {
      onprem_server = {
        hybrid_machine_id = azurerm_arc_machine.server.id
      }
    }
    ```
  EOT
  type = map(object({
    hybrid_machine_id = string
  }))
  default = {}
}

variable "vm_vulnerability_assessments" {
  description = <<-EOT
    Map of VM vulnerability assessment configurations.
    
    Example:
    ```hcl
    vm_vulnerability_assessments = {
      web_vm = {
        virtual_machine_id = azurerm_virtual_machine.web.id
      }
    }
    ```
  EOT
  type = map(object({
    virtual_machine_id = string
  }))
  default = {}
}

variable "storage_defender_settings" {
  description = <<-EOT
    Map of Defender for Storage settings per storage account.
    
    Allows per-account configuration overriding subscription defaults.
    
    Example:
    ```hcl
    storage_defender_settings = {
      sensitive_data = {
        storage_account_id              = azurerm_storage_account.sensitive.id
        override_subscription_settings  = true
        malware_scanning_enabled        = true
        malware_scanning_cap_gb         = 5000
        sensitive_data_discovery_enabled = true
      }
    }
    ```
  EOT
  type = map(object({
    storage_account_id               = string
    override_subscription_settings   = optional(bool, false)
    malware_scanning_enabled         = optional(bool, true)
    malware_scanning_cap_gb          = optional(number, 5000)
    sensitive_data_discovery_enabled = optional(bool, true)
  }))
  default = {}
}

variable "security_policy_assignments" {
  description = <<-EOT
    Map of security policy assignments.
    
    Common policies:
    - Azure Security Benchmark (recommended baseline)
    - CIS Microsoft Azure Foundations Benchmark
    - NIST SP 800-53
    - ISO 27001
    
    Example:
    ```hcl
    security_policy_assignments = {
      azure_security_benchmark = {
        name                 = "azure-security-benchmark"
        policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
        display_name         = "Azure Security Benchmark"
        location             = "eastus2"
        managed_identity     = true
      }
    }
    ```
  EOT
  type = map(object({
    name                   = string
    policy_definition_id   = string
    display_name           = optional(string)
    description            = optional(string)
    enforce                = optional(bool, true)
    location               = optional(string)
    managed_identity       = optional(bool, true)
    non_compliance_message = optional(string)
  }))
  default = {}
}

# Pre-defined policy set IDs for easy reference
locals {
  policy_sets = {
    azure_security_benchmark = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
    cis_1_4                  = "/providers/Microsoft.Authorization/policySetDefinitions/c3f5c4d9-9a1d-4a99-85c0-7f93e384d5c5"
    nist_sp_800_53_r5        = "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f"
    iso_27001                = "/providers/Microsoft.Authorization/policySetDefinitions/89c6cddc-1c73-4ac1-b19c-54d1a15a42f2"
    pci_dss_4_0              = "/providers/Microsoft.Authorization/policySetDefinitions/c676748e-3af9-4e22-bc28-50fed0f70084"
    hipaa                    = "/providers/Microsoft.Authorization/policySetDefinitions/a169a624-5599-4385-a696-c8d643089fab"
  }
}
