variable "managed_identities" {
  description = <<-EOT
    Map of user-assigned managed identities to create.
    Use managed identities instead of service principals with secrets.
    
    Example:
    ```hcl
    managed_identities = {
      app = {
        name                = "id-myapp-prod-eus2-001"
        resource_group_name = "rg-myapp-prod"
        location            = "eastus2"
        tags                = { environment = "prod" }
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

variable "role_assignments" {
  description = <<-EOT
    Map of role assignments to create.
    
    Attributes:
    - scope: The scope at which the role applies (subscription, RG, or resource ID)
    - role_name: Built-in role name (e.g., "Contributor", "Reader")
    - principal_id: The object ID of the principal (user, group, or managed identity)
    - skip_aad_check: Skip AAD check for service principal (helps with replication lag)
    - condition: Optional ABAC condition expression
    - condition_version: Condition version (default: "2.0")
    - description: Optional description
    
    Example:
    ```hcl
    role_assignments = {
      app_contributor = {
        scope        = "/subscriptions/xxx/resourceGroups/rg-myapp"
        role_name    = "Contributor"
        principal_id = "00000000-0000-0000-0000-000000000000"
      }
    }
    ```
  EOT
  type = map(object({
    scope             = string
    role_name         = string
    principal_id      = string
    skip_aad_check    = optional(bool, true)
    condition         = optional(string)
    condition_version = optional(string, "2.0")
    description       = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : can(regex("^/subscriptions/", v.scope))
    ])
    error_message = "Scope must be a valid Azure resource ID starting with /subscriptions/."
  }
}

variable "custom_roles" {
  description = <<-EOT
    Map of custom role definitions for least-privilege access.
    
    Use custom roles when built-in roles grant more permissions than needed.
    
    Example:
    ```hcl
    custom_roles = {
      container_app_operator = {
        name        = "Container Apps Operator"
        description = "Manage Container Apps without environment access"
        permissions = {
          actions = [
            "Microsoft.App/containerApps/read",
            "Microsoft.App/containerApps/write",
            "Microsoft.App/containerApps/delete"
          ]
          not_actions      = []
          data_actions     = []
          not_data_actions = []
        }
      }
    }
    ```
  EOT
  type = map(object({
    name        = string
    description = optional(string, "Custom role created by Terraform")
    scope       = optional(string)
    permissions = object({
      actions          = list(string)
      not_actions      = optional(list(string), [])
      data_actions     = optional(list(string), [])
      not_data_actions = optional(list(string), [])
    })
    assignable_scopes = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.custom_roles : length(v.permissions.actions) > 0
    ])
    error_message = "Custom roles must define at least one action."
  }
}

variable "identity_role_assignments" {
  description = <<-EOT
    Map of role assignments for managed identities created by this module.
    
    Links to identities via `identity_key` which references keys in `managed_identities`.
    
    Example:
    ```hcl
    identity_role_assignments = {
      app_keyvault_access = {
        identity_key = "app"
        scope        = "/subscriptions/xxx/resourceGroups/rg-myapp/providers/Microsoft.KeyVault/vaults/kv-myapp"
        role_name    = "Key Vault Secrets User"
      }
    }
    ```
  EOT
  type = map(object({
    identity_key = string
    scope        = string
    role_name    = string
    description  = optional(string)
  }))
  default = {}
}

# Common built-in role reference (for documentation)
locals {
  common_builtin_roles = {
    # General
    owner       = "Owner"
    contributor = "Contributor"
    reader      = "Reader"

    # Key Vault (RBAC mode)
    key_vault_administrator       = "Key Vault Administrator"
    key_vault_secrets_user        = "Key Vault Secrets User"
    key_vault_secrets_officer     = "Key Vault Secrets Officer"
    key_vault_crypto_user         = "Key Vault Crypto User"
    key_vault_certificates_officer = "Key Vault Certificates Officer"

    # Storage
    storage_blob_data_owner       = "Storage Blob Data Owner"
    storage_blob_data_contributor = "Storage Blob Data Contributor"
    storage_blob_data_reader      = "Storage Blob Data Reader"
    storage_queue_data_contributor = "Storage Queue Data Contributor"

    # SQL
    sql_db_contributor = "SQL DB Contributor"
    sql_server_contributor = "SQL Server Contributor"

    # Container Apps
    container_apps_contributor = "Container Apps Contributor"

    # Network
    network_contributor = "Network Contributor"

    # Monitoring
    monitoring_contributor = "Monitoring Contributor"
    monitoring_reader      = "Monitoring Reader"
    log_analytics_contributor = "Log Analytics Contributor"
  }
}
