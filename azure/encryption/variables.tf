variable "key_vaults" {
  description = <<-EOT
    Map of Key Vaults to create.
    
    Always uses RBAC authorization (enable_rbac_authorization = true).
    Do NOT use access policies - they are legacy and less secure.
    
    Example:
    ```hcl
    key_vaults = {
      main = {
        name                = "kv-myapp-prod-001"
        resource_group_name = "rg-myapp-prod"
        location            = "eastus2"
        sku_name            = "standard"
        purge_protection_enabled   = true
        soft_delete_retention_days = 90
        network_acls = {
          default_action = "Deny"
          bypass         = "AzureServices"
        }
      }
    }
    ```
  EOT
  type = map(object({
    name                            = string
    resource_group_name             = string
    location                        = string
    sku_name                        = optional(string, "standard")
    enabled_for_disk_encryption     = optional(bool, false)
    enabled_for_deployment          = optional(bool, false)
    enabled_for_template_deployment = optional(bool, false)
    purge_protection_enabled        = optional(bool, true)
    soft_delete_retention_days      = optional(number, 90)
    public_network_access_enabled   = optional(bool, false)
    admin_principal_id              = optional(string)
    tags                            = optional(map(string), {})
    network_acls = optional(object({
      bypass                     = optional(string, "AzureServices")
      default_action             = optional(string, "Deny")
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }), {
      bypass         = "AzureServices"
      default_action = "Deny"
      ip_rules       = []
      virtual_network_subnet_ids = []
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.key_vaults : contains(["standard", "premium"], v.sku_name)
    ])
    error_message = "SKU name must be 'standard' or 'premium'."
  }

  validation {
    condition = alltrue([
      for k, v in var.key_vaults : v.soft_delete_retention_days >= 7 && v.soft_delete_retention_days <= 90
    ])
    error_message = "Soft delete retention must be between 7 and 90 days."
  }
}

variable "keys" {
  description = <<-EOT
    Map of Key Vault keys to create for CMK encryption.
    
    Key operations:
    - decrypt, encrypt: Data encryption
    - sign, verify: Digital signatures
    - wrapKey, unwrapKey: Key wrapping for other keys
    
    Example:
    ```hcl
    keys = {
      storage = {
        name           = "cmk-storage"
        key_vault_key  = "main"
        key_type       = "RSA"
        key_size       = 2048
        key_ops        = ["decrypt", "encrypt", "wrapKey", "unwrapKey"]
        rotation_policy = {
          time_before_expiry   = "P30D"
          expire_after         = "P365D"
          notify_before_expiry = "P30D"
        }
      }
    }
    ```
  EOT
  type = map(object({
    name          = string
    key_vault_key = string # References key in key_vaults
    key_type      = optional(string, "RSA")
    key_size      = optional(number, 2048)
    key_ops = optional(list(string), [
      "decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"
    ])
    expiration_date = optional(string)
    tags            = optional(map(string), {})
    rotation_policy = optional(object({
      time_before_expiry   = optional(string, "P30D")
      expire_after         = optional(string)
      notify_before_expiry = optional(string, "P30D")
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.keys : contains(["RSA", "RSA-HSM", "EC", "EC-HSM"], v.key_type)
    ])
    error_message = "Key type must be RSA, RSA-HSM, EC, or EC-HSM."
  }

  validation {
    condition = alltrue([
      for k, v in var.keys :
      v.key_type != "RSA" && v.key_type != "RSA-HSM" ||
      contains([2048, 3072, 4096], v.key_size)
    ])
    error_message = "RSA key size must be 2048, 3072, or 4096."
  }
}

variable "secrets" {
  description = <<-EOT
    Map of Key Vault secrets to create.
    
    Use for sensitive data like connection strings, API keys, etc.
    
    Example:
    ```hcl
    secrets = {
      db_connection = {
        name          = "database-connection-string"
        key_vault_key = "main"
        value         = var.database_connection_string
        content_type  = "connection-string"
      }
    }
    ```
  EOT
  type = map(object({
    name            = string
    key_vault_key   = string # References key in key_vaults
    value           = string
    content_type    = optional(string)
    expiration_date = optional(string)
    not_before_date = optional(string)
    tags            = optional(map(string), {})
  }))
  default   = {}
  sensitive = true
}

variable "private_endpoints" {
  description = <<-EOT
    Map of private endpoints for Key Vault.
    
    Example:
    ```hcl
    private_endpoints = {
      main = {
        name                 = "pep-kv-myapp-prod"
        resource_group_name  = "rg-network-prod"
        location             = "eastus2"
        subnet_id            = azurerm_subnet.private_endpoints.id
        key_vault_key        = "main"
        private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
      }
    }
    ```
  EOT
  type = map(object({
    name                 = string
    resource_group_name  = string
    location             = string
    subnet_id            = string
    key_vault_key        = string # References key in key_vaults
    private_dns_zone_ids = optional(list(string))
    tags                 = optional(map(string), {})
  }))
  default = {}
}

variable "role_assignments" {
  description = <<-EOT
    Map of RBAC role assignments for Key Vault.
    
    Common roles:
    - Key Vault Administrator: Full control
    - Key Vault Secrets User: Read secrets only
    - Key Vault Secrets Officer: Manage secrets
    - Key Vault Crypto User: Use keys for cryptographic ops
    - Key Vault Certificates Officer: Manage certificates
    
    Example:
    ```hcl
    role_assignments = {
      app_secrets_access = {
        key_vault_key = "main"
        role_name     = "Key Vault Secrets User"
        principal_id  = azurerm_user_assigned_identity.app.principal_id
      }
    }
    ```
  EOT
  type = map(object({
    key_vault_key = string
    role_name     = string
    principal_id  = string
    description   = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : contains([
        "Key Vault Administrator",
        "Key Vault Secrets User",
        "Key Vault Secrets Officer",
        "Key Vault Crypto User",
        "Key Vault Crypto Officer",
        "Key Vault Certificates Officer",
        "Key Vault Reader"
      ], v.role_name)
    ])
    error_message = "Invalid Key Vault role name."
  }
}

variable "storage_cmk_configs" {
  description = <<-EOT
    Map of storage account CMK configurations.
    
    Enables customer-managed key encryption for Azure Storage.
    Requires a user-assigned managed identity with Key Vault Crypto User role.
    
    Example:
    ```hcl
    storage_cmk_configs = {
      data_storage = {
        storage_account_id        = azurerm_storage_account.data.id
        key_vault_key             = "main"
        key_key                   = "storage"
        user_assigned_identity_id = azurerm_user_assigned_identity.storage.id
      }
    }
    ```
  EOT
  type = map(object({
    storage_account_id        = string
    key_vault_key             = string # References key in key_vaults
    key_key                   = string # References key in keys
    user_assigned_identity_id = string
  }))
  default = {}
}
