/**
 * # Network Security Module
 *
 * Provides Azure network security foundation with:
 * - Network Security Groups (NSGs) with tier-based templates
 * - Application Security Groups (ASGs) for logical grouping
 * - NSG Flow Logs for traffic analysis
 */

# -----------------------------------------------------------------------------
# Application Security Groups
# Logical grouping of NICs for simplified NSG rules
# -----------------------------------------------------------------------------
resource "azurerm_application_security_group" "groups" {
  for_each = var.application_security_groups

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}

# -----------------------------------------------------------------------------
# Network Security Groups
# Stateful firewall rules for subnets and NICs
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsgs" {
  for_each = var.network_security_groups

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}

# -----------------------------------------------------------------------------
# NSG Security Rules
# Individual rules for each NSG
# -----------------------------------------------------------------------------
resource "azurerm_network_security_rule" "rules" {
  for_each = local.flattened_rules

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_port_ranges          = each.value.source_port_ranges
  destination_port_ranges     = each.value.destination_port_ranges
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  source_address_prefixes     = each.value.source_address_prefixes
  destination_address_prefixes = each.value.destination_address_prefixes
  
  # ASG references
  source_application_security_group_ids      = each.value.source_asg_keys != null ? [for k in each.value.source_asg_keys : azurerm_application_security_group.groups[k].id] : null
  destination_application_security_group_ids = each.value.destination_asg_keys != null ? [for k in each.value.destination_asg_keys : azurerm_application_security_group.groups[k].id] : null

  resource_group_name         = each.value.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsgs[each.value.nsg_key].name

  description = each.value.description
}

# -----------------------------------------------------------------------------
# NSG-Subnet Associations
# Attach NSGs to subnets
# -----------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "associations" {
  for_each = var.nsg_subnet_associations

  subnet_id                 = each.value.subnet_id
  network_security_group_id = azurerm_network_security_group.nsgs[each.value.nsg_key].id
}

# -----------------------------------------------------------------------------
# NSG Flow Logs
# Traffic analysis and auditing
# -----------------------------------------------------------------------------
resource "azurerm_network_watcher_flow_log" "flow_logs" {
  for_each = var.nsg_flow_logs

  name                 = each.value.name
  network_watcher_name = each.value.network_watcher_name
  resource_group_name  = each.value.network_watcher_resource_group

  network_security_group_id = azurerm_network_security_group.nsgs[each.value.nsg_key].id
  storage_account_id        = each.value.storage_account_id
  enabled                   = each.value.enabled
  version                   = each.value.version

  retention_policy {
    enabled = each.value.retention_enabled
    days    = each.value.retention_days
  }

  dynamic "traffic_analytics" {
    for_each = each.value.traffic_analytics != null ? [each.value.traffic_analytics] : []
    content {
      enabled               = traffic_analytics.value.enabled
      workspace_id          = traffic_analytics.value.workspace_id
      workspace_region      = traffic_analytics.value.workspace_region
      workspace_resource_id = traffic_analytics.value.workspace_resource_id
      interval_in_minutes   = traffic_analytics.value.interval_in_minutes
    }
  }

  tags = each.value.tags
}

# -----------------------------------------------------------------------------
# Locals - Flatten rules for for_each
# -----------------------------------------------------------------------------
locals {
  flattened_rules = merge([
    for nsg_key, nsg in var.network_security_groups : {
      for rule_key, rule in coalesce(nsg.rules, {}) :
      "${nsg_key}-${rule_key}" => merge(rule, {
        nsg_key             = nsg_key
        resource_group_name = nsg.resource_group_name
      })
    }
  ]...)
}
