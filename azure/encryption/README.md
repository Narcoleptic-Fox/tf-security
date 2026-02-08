# Encryption Module

Azure Key Vault and customer-managed keys.

## Planned Features

- [ ] Key Vault with soft delete
- [ ] Key Vault access policies
- [ ] Customer-managed keys for storage
- [ ] Disk encryption sets
- [ ] SQL TDE with CMK
- [ ] Certificate management
- [ ] Secret rotation

## Usage (Coming Soon)

```hcl
module "encryption" {
  source = "github.com/Narcoleptic-Fox/tf-security//azure/encryption"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  naming_prefix       = module.naming.prefix
  tags                = module.tags.azure_tags
}

# Use the key
resource "azurerm_storage_account" "data" {
  # ...
  customer_managed_key {
    key_vault_key_id = module.encryption.storage_key_id
  }
}
```
