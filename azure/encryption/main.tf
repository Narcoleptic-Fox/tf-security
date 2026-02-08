/**
 * # Encryption Module
 *
 * Provides Azure encryption foundation with:
 * - Key Vault with RBAC authorization (not access policies!)
 * - Customer-managed keys (CMK) for data encryption
 * - Private endpoints for network isolation
 */

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# Key Vault
# Uses RBAC authorization instead of access policies (best practice)
# -----------------------------------------------------------------------------
resource "azurerm_key_vault" "vault" {
  for_each = var.key_vaults

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = each.value.sku_name

  # Security settings
  enabled_for_disk_encryption     = each.value.enabled_for_disk_encryption
  enabled_for_deployment          = each.value.enabled_for_deployment
  enabled_for_template_deployment = each.value.enabled_for_template_deployment
  enable_rbac_authorization       = true # Always use RBAC, not access policies!
  purge_protection_enabled        = each.value.purge_protection_enabled
  soft_delete_retention_days      = each.value.soft_delete_retention_days

  # Network configuration
  public_network_access_enabled = each.value.public_network_access_enabled

  network_acls {
    bypass                     = each.value.network_acls.bypass
    default_action             = each.value.network_acls.default_action
    ip_rules                   = each.value.network_acls.ip_rules
    virtual_network_subnet_ids = each.value.network_acls.virtual_network_subnet_ids
  }

  tags = each.value.tags
}

# -----------------------------------------------------------------------------
# Key Vault Keys
# Used for customer-managed encryption (CMK)
# -----------------------------------------------------------------------------
resource "azurerm_key_vault_key" "keys" {
  for_each = var.keys

  name         = each.value.name
  key_vault_id = azurerm_key_vault.vault[each.value.key_vault_key].id
  key_type     = each.value.key_type
  key_size     = each.value.key_size

  key_opts = each.value.key_ops

  # Rotation policy
  dynamic "rotation_policy" {
    for_each = each.value.rotation_policy != null ? [each.value.rotation_policy] : []
    content {
      automatic {
        time_before_expiry = rotation_policy.value.time_before_expiry
      }
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry
    }
  }

  expiration_date = each.value.expiration_date

  tags = each.value.tags

  depends_on = [azurerm_role_assignment.admin_role]
}

# -----------------------------------------------------------------------------
# Key Vault Secrets
# For application secrets (connection strings, API keys, etc.)
# -----------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name            = each.value.name
  value           = each.value.value
  key_vault_id    = azurerm_key_vault.vault[each.value.key_vault_key].id
  content_type    = each.value.content_type
  expiration_date = each.value.expiration_date
  not_before_date = each.value.not_before_date

  tags = each.value.tags

  depends_on = [azurerm_role_assignment.admin_role]
}

# -----------------------------------------------------------------------------
# Private Endpoints
# Secure access to Key Vault over private network
# -----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "keyvault" {
  for_each = var.private_endpoints

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "psc-${each.value.name}"
    private_connection_resource_id = azurerm_key_vault.vault[each.value.key_vault_key].id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_zone_ids != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = each.value.private_dns_zone_ids
    }
  }

  tags = each.value.tags
}

# -----------------------------------------------------------------------------
# RBAC Role Assignments
# Grant access to Key Vault using RBAC (not access policies)
# -----------------------------------------------------------------------------

# Admin role for the current principal (to manage keys/secrets)
resource "azurerm_role_assignment" "admin_role" {
  for_each = var.key_vaults

  scope                = azurerm_key_vault.vault[each.key].id
  role_definition_name = "Key Vault Administrator"
  principal_id         = coalesce(each.value.admin_principal_id, data.azurerm_client_config.current.object_id)
}

# Additional role assignments
resource "azurerm_role_assignment" "keyvault_roles" {
  for_each = var.role_assignments

  scope                            = azurerm_key_vault.vault[each.value.key_vault_key].id
  role_definition_name             = each.value.role_name
  principal_id                     = each.value.principal_id
  skip_service_principal_aad_check = true

  description = each.value.description
}

# -----------------------------------------------------------------------------
# CMK for Storage Accounts
# Enable customer-managed keys on storage accounts
# -----------------------------------------------------------------------------
resource "azurerm_storage_account_customer_managed_key" "cmk" {
  for_each = var.storage_cmk_configs

  storage_account_id        = each.value.storage_account_id
  key_vault_id              = azurerm_key_vault.vault[each.value.key_vault_key].id
  key_name                  = azurerm_key_vault_key.keys[each.value.key_key].name
  user_assigned_identity_id = each.value.user_assigned_identity_id
}
