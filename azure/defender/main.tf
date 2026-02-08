/**
 * # Defender Module
 *
 * Provides Microsoft Defender for Cloud configuration with:
 * - Defender plans enablement for various resource types
 * - Security contacts for alert notifications
 * - Auto-provisioning settings for agents
 * - Defender for DevOps integration
 */

data "azurerm_subscription" "current" {}

# -----------------------------------------------------------------------------
# Defender Plans
# Enable Microsoft Defender for various resource types
# -----------------------------------------------------------------------------
resource "azurerm_security_center_subscription_pricing" "plans" {
  for_each = var.defender_plans

  tier          = each.value.tier
  resource_type = each.value.resource_type
  subplan       = each.value.subplan

  dynamic "extension" {
    for_each = each.value.extensions != null ? each.value.extensions : []
    content {
      name = extension.value.name
      additional_extension_properties = extension.value.additional_properties
    }
  }
}

# -----------------------------------------------------------------------------
# Security Contacts
# Configure who receives security alerts
# -----------------------------------------------------------------------------
resource "azurerm_security_center_contact" "contacts" {
  for_each = var.security_contacts

  email               = each.value.email
  phone               = each.value.phone
  alert_notifications = each.value.alert_notifications
  alerts_to_admins    = each.value.alerts_to_admins
  name                = each.value.name
}

# -----------------------------------------------------------------------------
# Auto Provisioning
# Automatically deploy monitoring agents
# -----------------------------------------------------------------------------
resource "azurerm_security_center_auto_provisioning" "auto_provisioning" {
  for_each = var.auto_provisioning_settings

  auto_provision = each.value.enabled ? "On" : "Off"
}

# -----------------------------------------------------------------------------
# Security Center Workspace (Log Analytics connection)
# Define where Defender sends data
# -----------------------------------------------------------------------------
resource "azurerm_security_center_workspace" "workspace" {
  for_each = var.workspace_settings

  scope        = each.value.scope != null ? each.value.scope : data.azurerm_subscription.current.id
  workspace_id = each.value.workspace_id
}

# -----------------------------------------------------------------------------
# Defender for Servers Settings
# Configure Defender for Servers specific options
# -----------------------------------------------------------------------------
resource "azurerm_security_center_server_vulnerability_assessment" "assessment" {
  for_each = var.server_vulnerability_assessment

  hybrid_machine_id = each.value.hybrid_machine_id
}

# Virtual Machine vulnerability assessment using built-in solution
resource "azurerm_security_center_server_vulnerability_assessment_virtual_machine" "vm_assessment" {
  for_each = var.vm_vulnerability_assessments

  virtual_machine_id = each.value.virtual_machine_id
}

# -----------------------------------------------------------------------------
# Defender for Storage Settings
# Configure Defender for Storage specific options
# -----------------------------------------------------------------------------
resource "azurerm_security_center_storage_defender" "storage" {
  for_each = var.storage_defender_settings

  storage_account_id                          = each.value.storage_account_id
  override_subscription_settings_enabled      = each.value.override_subscription_settings
  malware_scanning_on_upload_enabled          = each.value.malware_scanning_enabled
  malware_scanning_on_upload_cap_gb_per_month = each.value.malware_scanning_cap_gb
  sensitive_data_discovery_enabled            = each.value.sensitive_data_discovery_enabled
}

# -----------------------------------------------------------------------------
# Subscription-level Security Assessment
# Configure security policy
# -----------------------------------------------------------------------------
resource "azurerm_subscription_policy_assignment" "security_benchmark" {
  for_each = var.security_policy_assignments

  name                 = each.value.name
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = each.value.policy_definition_id
  display_name         = each.value.display_name
  description          = each.value.description
  enforce              = each.value.enforce

  dynamic "identity" {
    for_each = each.value.managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  location = each.value.location

  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_message != null ? [1] : []
    content {
      content = each.value.non_compliance_message
    }
  }
}

# -----------------------------------------------------------------------------
# Locals - Common Defender plan configurations
# -----------------------------------------------------------------------------
locals {
  # Standard Defender plans with their resource types
  standard_plans = {
    virtual_machines    = "VirtualMachines"
    sql_servers         = "SqlServers"
    app_services        = "AppServices"
    storage_accounts    = "StorageAccounts"
    containers          = "Containers"
    key_vaults          = "KeyVaults"
    dns                 = "Dns"
    arm                 = "Arm"
    open_source_dbs     = "OpenSourceRelationalDatabases"
    cosmos_dbs          = "CosmosDbs"
    sql_server_vms      = "SqlServerVirtualMachines"
    api_management      = "Api"
  }
  
  # Azure Security Benchmark policy definition ID
  azure_security_benchmark_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
}
