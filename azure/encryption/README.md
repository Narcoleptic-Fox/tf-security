# Azure Encryption Module

Provides Azure encryption foundation with Key Vault (RBAC mode), customer-managed keys (CMK), and private endpoints for secure secret and key management.

## Features

- **Key Vault with RBAC** - Uses RBAC authorization (not legacy access policies)
- **Customer-Managed Keys** - CMK for storage, SQL, and other Azure services
- **Private Endpoints** - Network isolation for Key Vault access
- **Key Rotation** - Automatic key rotation policies
- **Soft Delete & Purge Protection** - Data recovery safeguards

## Security Best Practices

1. **RBAC Over Access Policies** - Always use RBAC (enable_rbac_authorization = true)
2. **Purge Protection** - Enable to prevent accidental deletion
3. **Private Endpoints** - Disable public access in production
4. **Managed Identities** - Use managed identities for Key Vault access
5. **Key Rotation** - Configure automatic rotation for long-lived keys

## Usage

### Basic Key Vault with Secrets

```hcl
module "naming" {
  source = "../../core/naming"
  
  project     = "myapp"
  environment = "prod"
  region      = "eastus2"
}

module "tagging" {
  source = "../../core/tagging"
  
  project     = "myapp"
  environment = "prod"
  owner       = "platform-team"
  cost_center = "engineering"
}

module "encryption" {
  source = "../../azure/encryption"
  
  key_vaults = {
    main = {
      name                          = module.naming.key_vault_name
      resource_group_name           = azurerm_resource_group.main.name
      location                      = azurerm_resource_group.main.location
      purge_protection_enabled      = true
      soft_delete_retention_days    = 90
      public_network_access_enabled = false
      tags                          = module.tagging.azure_tags
      
      network_acls = {
        default_action = "Deny"
        bypass         = "AzureServices"
      }
    }
  }
  
  secrets = {
    db_connection = {
      name          = "database-connection-string"
      key_vault_key = "main"
      value         = var.database_connection_string
      content_type  = "connection-string"
    }
    api_key = {
      name          = "external-api-key"
      key_vault_key = "main"
      value         = var.api_key
      content_type  = "api-key"
    }
  }
  
  role_assignments = {
    app_secrets = {
      key_vault_key = "main"
      role_name     = "Key Vault Secrets User"
      principal_id  = module.rbac.identity_principal_ids["app"]
    }
  }
}
```

### Customer-Managed Keys for Storage

```hcl
module "encryption" {
  source = "../../azure/encryption"
  
  key_vaults = {
    cmk = {
      name                          = "kv-cmk-prod-001"
      resource_group_name           = azurerm_resource_group.main.name
      location                      = "eastus2"
      sku_name                      = "premium"  # Required for HSM-backed keys
      purge_protection_enabled      = true
      public_network_access_enabled = false
    }
  }
  
  keys = {
    storage = {
      name          = "cmk-storage"
      key_vault_key = "cmk"
      key_type      = "RSA"
      key_size      = 2048
      key_ops       = ["decrypt", "encrypt", "wrapKey", "unwrapKey"]
      
      rotation_policy = {
        time_before_expiry   = "P30D"   # Rotate 30 days before expiry
        expire_after         = "P365D"  # Key expires after 1 year
        notify_before_expiry = "P30D"   # Notify 30 days before
      }
    }
  }
  
  # Grant storage identity access to use the key
  role_assignments = {
    storage_cmk_access = {
      key_vault_key = "cmk"
      role_name     = "Key Vault Crypto User"
      principal_id  = azurerm_user_assigned_identity.storage.principal_id
    }
  }
  
  # Enable CMK on storage account
  storage_cmk_configs = {
    data = {
      storage_account_id        = azurerm_storage_account.data.id
      key_vault_key             = "cmk"
      key_key                   = "storage"
      user_assigned_identity_id = azurerm_user_assigned_identity.storage.id
    }
  }
}

# Storage account must have identity configured
resource "azurerm_storage_account" "data" {
  name                     = "stmyappprod001"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = "eastus2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.storage.id]
  }
}
```

### Private Endpoint Configuration

```hcl
# Private DNS zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "link-keyvault"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

module "encryption" {
  source = "../../azure/encryption"
  
  key_vaults = {
    main = {
      name                          = "kv-myapp-prod-001"
      resource_group_name           = azurerm_resource_group.main.name
      location                      = "eastus2"
      public_network_access_enabled = false  # No public access
      purge_protection_enabled      = true
    }
  }
  
  private_endpoints = {
    main = {
      name                 = "pep-kv-myapp-prod"
      resource_group_name  = azurerm_resource_group.main.name
      location             = "eastus2"
      subnet_id            = azurerm_subnet.private_endpoints.id
      key_vault_key        = "main"
      private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| key_vaults | Map of Key Vaults to create | `map(object)` | `{}` | no |
| keys | Map of Key Vault keys for CMK | `map(object)` | `{}` | no |
| secrets | Map of Key Vault secrets | `map(object)` | `{}` | no |
| private_endpoints | Map of private endpoints | `map(object)` | `{}` | no |
| role_assignments | Map of RBAC assignments | `map(object)` | `{}` | no |
| storage_cmk_configs | Map of storage CMK configs | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| key_vaults | Map of created Key Vaults |
| key_vault_ids | Map of Key Vault keys to resource IDs |
| key_vault_uris | Map of Key Vault keys to URIs |
| keys | Map of created keys |
| key_versionless_ids | Versionless key IDs (for auto-rotation) |
| secrets | Map of created secrets (IDs only) |
| secret_versionless_ids | Versionless secret IDs |
| private_endpoints | Map of created private endpoints |

## Key Vault RBAC Roles

| Role | Use Case |
|------|----------|
| Key Vault Administrator | Full control (admins) |
| Key Vault Secrets User | Read secrets (apps) |
| Key Vault Secrets Officer | Manage secrets (ops) |
| Key Vault Crypto User | Use keys for encryption (CMK) |
| Key Vault Crypto Officer | Manage keys |
| Key Vault Certificates Officer | Manage certificates |
| Key Vault Reader | Read metadata only |

## Security Considerations

### Do

- ✅ Always enable RBAC authorization
- ✅ Enable purge protection for production vaults
- ✅ Use private endpoints to disable public access
- ✅ Configure key rotation policies
- ✅ Use managed identities for Key Vault access
- ✅ Use versionless IDs for secrets/keys to enable rotation

### Don't

- ❌ Never use access policies (legacy)
- ❌ Never store secrets in Terraform state (use data sources)
- ❌ Don't disable soft delete
- ❌ Avoid granting Key Vault Administrator broadly
- ❌ Don't use static secret versions (prevents rotation)

## CMK Support Matrix

| Azure Service | CMK Support |
|---------------|-------------|
| Azure Storage | ✅ (blob, file, queue, table) |
| Azure SQL | ✅ (TDE) |
| Azure Cosmos DB | ✅ |
| Azure Disk | ✅ |
| Azure Backup | ✅ |
| Log Analytics | ✅ |

## License

MIT
