# Key Vault outputs
output "key_vaults" {
  description = "Map of created Key Vaults with their details"
  value = {
    for k, v in azurerm_key_vault.vault : k => {
      id        = v.id
      name      = v.name
      vault_uri = v.vault_uri
      location  = v.location
    }
  }
}

output "key_vault_ids" {
  description = "Map of Key Vault keys to their resource IDs"
  value       = { for k, v in azurerm_key_vault.vault : k => v.id }
}

output "key_vault_uris" {
  description = "Map of Key Vault keys to their URIs"
  value       = { for k, v in azurerm_key_vault.vault : k => v.vault_uri }
}

# Key outputs
output "keys" {
  description = "Map of created keys"
  value = {
    for k, v in azurerm_key_vault_key.keys : k => {
      id                  = v.id
      name                = v.name
      version             = v.version
      versionless_id      = v.versionless_id
      resource_id         = v.resource_id
      resource_versionless_id = v.resource_versionless_id
    }
  }
}

output "key_ids" {
  description = "Map of key keys to their resource IDs (with version)"
  value       = { for k, v in azurerm_key_vault_key.keys : k => v.id }
}

output "key_versionless_ids" {
  description = "Map of key keys to their versionless IDs (for auto-rotation)"
  value       = { for k, v in azurerm_key_vault_key.keys : k => v.versionless_id }
}

# Secret outputs (IDs only, not values)
output "secrets" {
  description = "Map of created secrets (IDs only, values are sensitive)"
  value = {
    for k, v in azurerm_key_vault_secret.secrets : k => {
      id             = v.id
      name           = v.name
      version        = v.version
      versionless_id = v.versionless_id
    }
  }
}

output "secret_ids" {
  description = "Map of secret keys to their resource IDs (with version)"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "secret_versionless_ids" {
  description = "Map of secret keys to their versionless IDs"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.versionless_id }
}

# Private Endpoint outputs
output "private_endpoints" {
  description = "Map of created private endpoints"
  value = {
    for k, v in azurerm_private_endpoint.keyvault : k => {
      id                 = v.id
      name               = v.name
      private_ip_address = v.private_service_connection[0].private_ip_address
    }
  }
}

# Role Assignment outputs
output "role_assignments" {
  description = "Map of created role assignments"
  value = {
    for k, v in azurerm_role_assignment.keyvault_roles : k => {
      id           = v.id
      scope        = v.scope
      role_name    = v.role_definition_name
      principal_id = v.principal_id
    }
  }
}

# CMK configuration outputs
output "storage_cmk_configs" {
  description = "Map of storage CMK configurations"
  value = {
    for k, v in azurerm_storage_account_customer_managed_key.cmk : k => {
      storage_account_id = v.storage_account_id
      key_vault_id       = v.key_vault_id
      key_name           = v.key_name
    }
  }
}
