# Managed Identity outputs
output "managed_identities" {
  description = "Map of created managed identities with their details"
  value = {
    for k, v in azurerm_user_assigned_identity.identities : k => {
      id           = v.id
      principal_id = v.principal_id
      client_id    = v.client_id
      tenant_id    = v.tenant_id
      name         = v.name
    }
  }
}

output "identity_ids" {
  description = "Map of managed identity keys to their resource IDs"
  value       = { for k, v in azurerm_user_assigned_identity.identities : k => v.id }
}

output "identity_principal_ids" {
  description = "Map of managed identity keys to their principal IDs (for role assignments)"
  value       = { for k, v in azurerm_user_assigned_identity.identities : k => v.principal_id }
}

output "identity_client_ids" {
  description = "Map of managed identity keys to their client IDs (for app configuration)"
  value       = { for k, v in azurerm_user_assigned_identity.identities : k => v.client_id }
}

# Role Assignment outputs
output "role_assignments" {
  description = "Map of created role assignments"
  value = {
    for k, v in azurerm_role_assignment.builtin : k => {
      id                   = v.id
      scope                = v.scope
      role_definition_name = v.role_definition_name
      principal_id         = v.principal_id
    }
  }
}

output "identity_role_assignments" {
  description = "Map of role assignments for managed identities"
  value = {
    for k, v in azurerm_role_assignment.identity_roles : k => {
      id                   = v.id
      scope                = v.scope
      role_definition_name = v.role_definition_name
      principal_id         = v.principal_id
    }
  }
}

# Custom Role outputs
output "custom_roles" {
  description = "Map of created custom role definitions"
  value = {
    for k, v in azurerm_role_definition.custom : k => {
      id                 = v.id
      role_definition_id = v.role_definition_id
      name               = v.name
      scope              = v.scope
    }
  }
}

output "custom_role_ids" {
  description = "Map of custom role keys to their role definition IDs"
  value       = { for k, v in azurerm_role_definition.custom : k => v.role_definition_id }
}

# Subscription context
output "subscription_id" {
  description = "Current subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

output "tenant_id" {
  description = "Current tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}
