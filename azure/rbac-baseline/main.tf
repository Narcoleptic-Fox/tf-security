/**
 * # RBAC Baseline Module
 *
 * Provides Azure RBAC foundation with:
 * - User-assigned managed identities (preferred over service principals)
 * - Built-in role assignments
 * - Custom role definitions for least privilege
 */

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# User-Assigned Managed Identity
# Use this instead of service principals with secrets
# -----------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "identities" {
  for_each = var.managed_identities

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}

# -----------------------------------------------------------------------------
# Built-in Role Assignments
# Assign Azure built-in roles to principals (users, groups, managed identities)
# -----------------------------------------------------------------------------
resource "azurerm_role_assignment" "builtin" {
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_name
  principal_id         = each.value.principal_id

  # Prevent recreation when Azure AD replicates slowly
  skip_service_principal_aad_check = each.value.skip_aad_check

  # Conditions for fine-grained access (ABAC)
  condition         = each.value.condition
  condition_version = each.value.condition != null ? each.value.condition_version : null

  description = each.value.description
}

# -----------------------------------------------------------------------------
# Custom Role Definitions
# Create least-privilege custom roles when built-in roles are too broad
# -----------------------------------------------------------------------------
resource "azurerm_role_definition" "custom" {
  for_each = var.custom_roles

  name        = each.value.name
  scope       = coalesce(each.value.scope, data.azurerm_subscription.current.id)
  description = each.value.description

  permissions {
    actions          = each.value.permissions.actions
    not_actions      = each.value.permissions.not_actions
    data_actions     = each.value.permissions.data_actions
    not_data_actions = each.value.permissions.not_data_actions
  }

  assignable_scopes = length(each.value.assignable_scopes) > 0 ? each.value.assignable_scopes : [data.azurerm_subscription.current.id]
}

# -----------------------------------------------------------------------------
# Role Assignments for Managed Identities
# Assign roles to the managed identities created by this module
# -----------------------------------------------------------------------------
resource "azurerm_role_assignment" "identity_roles" {
  for_each = var.identity_role_assignments

  scope                            = each.value.scope
  role_definition_name             = each.value.role_name
  principal_id                     = azurerm_user_assigned_identity.identities[each.value.identity_key].principal_id
  skip_service_principal_aad_check = true

  description = each.value.description
}
