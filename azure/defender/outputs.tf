# Defender Plan outputs
output "defender_plans" {
  description = "Map of enabled Defender plans"
  value = {
    for k, v in azurerm_security_center_subscription_pricing.plans : k => {
      id            = v.id
      resource_type = v.resource_type
      tier          = v.tier
    }
  }
}

output "enabled_plans" {
  description = "List of enabled Defender plan resource types"
  value = [
    for k, v in azurerm_security_center_subscription_pricing.plans :
    v.resource_type if v.tier == "Standard"
  ]
}

# Security Contact outputs
output "security_contacts" {
  description = "Map of configured security contacts"
  value = {
    for k, v in azurerm_security_center_contact.contacts : k => {
      id    = v.id
      email = v.email
      name  = v.name
    }
  }
}

# Auto Provisioning outputs
output "auto_provisioning" {
  description = "Map of auto-provisioning settings"
  value = {
    for k, v in azurerm_security_center_auto_provisioning.auto_provisioning : k => {
      id           = v.id
      auto_provision = v.auto_provision
    }
  }
}

# Workspace Settings outputs
output "workspace_settings" {
  description = "Map of workspace configurations"
  value = {
    for k, v in azurerm_security_center_workspace.workspace : k => {
      id           = v.id
      workspace_id = v.workspace_id
      scope        = v.scope
    }
  }
}

# Storage Defender outputs
output "storage_defender_settings" {
  description = "Map of storage-specific Defender settings"
  value = {
    for k, v in azurerm_security_center_storage_defender.storage : k => {
      id                 = v.id
      storage_account_id = v.storage_account_id
    }
  }
}

# Policy Assignment outputs
output "security_policy_assignments" {
  description = "Map of security policy assignments"
  value = {
    for k, v in azurerm_subscription_policy_assignment.security_benchmark : k => {
      id           = v.id
      name         = v.name
      display_name = v.display_name
    }
  }
}

# Subscription context
output "subscription_id" {
  description = "Current subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

# Policy set IDs for reference
output "policy_set_ids" {
  description = "Common security policy set IDs for reference"
  value       = local.policy_sets
}
