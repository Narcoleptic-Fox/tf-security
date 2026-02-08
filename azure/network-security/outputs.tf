# Application Security Group outputs
output "application_security_groups" {
  description = "Map of created Application Security Groups"
  value = {
    for k, v in azurerm_application_security_group.groups : k => {
      id       = v.id
      name     = v.name
      location = v.location
    }
  }
}

output "asg_ids" {
  description = "Map of ASG keys to their resource IDs"
  value       = { for k, v in azurerm_application_security_group.groups : k => v.id }
}

# Network Security Group outputs
output "network_security_groups" {
  description = "Map of created Network Security Groups"
  value = {
    for k, v in azurerm_network_security_group.nsgs : k => {
      id       = v.id
      name     = v.name
      location = v.location
    }
  }
}

output "nsg_ids" {
  description = "Map of NSG keys to their resource IDs"
  value       = { for k, v in azurerm_network_security_group.nsgs : k => v.id }
}

# Security Rule outputs
output "security_rules" {
  description = "Map of created security rules"
  value = {
    for k, v in azurerm_network_security_rule.rules : k => {
      id        = v.id
      name      = v.name
      priority  = v.priority
      direction = v.direction
      access    = v.access
    }
  }
}

# NSG Flow Log outputs
output "flow_logs" {
  description = "Map of created NSG flow logs"
  value = {
    for k, v in azurerm_network_watcher_flow_log.flow_logs : k => {
      id                 = v.id
      name               = v.name
      enabled            = v.enabled
      storage_account_id = v.storage_account_id
    }
  }
}

# Subnet association outputs
output "subnet_associations" {
  description = "Map of NSG-subnet associations"
  value = {
    for k, v in azurerm_subnet_network_security_group_association.associations : k => {
      id                        = v.id
      subnet_id                 = v.subnet_id
      network_security_group_id = v.network_security_group_id
    }
  }
}

# Tier templates for reference
output "tier_templates" {
  description = "Pre-built tier templates for reference"
  value       = var.tier_templates
}
