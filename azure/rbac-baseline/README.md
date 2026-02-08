# Azure RBAC Baseline Module

Provides Azure Role-Based Access Control (RBAC) foundation including user-assigned managed identities, built-in role assignments, and custom role definitions.

## Features

- **User-Assigned Managed Identities** - Preferred over service principals with secrets
- **Built-in Role Assignments** - Assign Azure roles to any principal
- **Custom Role Definitions** - Create least-privilege roles when built-in roles are too broad
- **ABAC Support** - Attribute-based access control conditions for fine-grained permissions

## Security Best Practices

This module follows Azure security best practices:

1. **Use Managed Identities** - Never use service principals with secrets in production
2. **Least Privilege** - Custom roles for minimal required permissions
3. **RBAC over Access Policies** - Use Key Vault RBAC mode instead of legacy access policies
4. **Skip AAD Check** - Enabled by default to handle AAD replication delays

## Usage

### Basic - Managed Identity with Role Assignment

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

module "rbac" {
  source = "../../azure/rbac-baseline"
  
  managed_identities = {
    app = {
      name                = "id-${module.naming.prefix}-001"
      resource_group_name = azurerm_resource_group.main.name
      location            = azurerm_resource_group.main.location
      tags                = module.tagging.azure_tags
    }
  }
  
  identity_role_assignments = {
    keyvault_secrets = {
      identity_key = "app"
      scope        = azurerm_key_vault.main.id
      role_name    = "Key Vault Secrets User"
    }
    storage_blob = {
      identity_key = "app"
      scope        = azurerm_storage_account.main.id
      role_name    = "Storage Blob Data Contributor"
    }
  }
}

# Reference in Container App
resource "azurerm_container_app" "api" {
  # ...
  identity {
    type         = "UserAssigned"
    identity_ids = [module.rbac.identity_ids["app"]]
  }
  
  template {
    container {
      env {
        name  = "AZURE_CLIENT_ID"
        value = module.rbac.identity_client_ids["app"]
      }
    }
  }
}
```

### Custom Role for Least Privilege

```hcl
module "rbac" {
  source = "../../azure/rbac-baseline"
  
  custom_roles = {
    container_app_operator = {
      name        = "Container Apps Operator"
      description = "Operate Container Apps without environment management"
      permissions = {
        actions = [
          "Microsoft.App/containerApps/read",
          "Microsoft.App/containerApps/write",
          "Microsoft.App/containerApps/delete",
          "Microsoft.App/containerApps/revisions/*",
          "Microsoft.App/containerApps/listSecrets/action"
        ]
      }
    }
    
    keyvault_reader_no_secrets = {
      name        = "Key Vault Metadata Reader"
      description = "Read Key Vault metadata without accessing secret values"
      permissions = {
        actions = [
          "Microsoft.KeyVault/vaults/read",
          "Microsoft.KeyVault/vaults/keys/read",
          "Microsoft.KeyVault/vaults/secrets/read"
        ]
        not_data_actions = [
          "Microsoft.KeyVault/vaults/secrets/getSecret/action"
        ]
      }
    }
  }
  
  role_assignments = {
    ops_team = {
      scope        = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/rg-myapp-prod"
      role_name    = "Container Apps Operator"  # Use custom role after creation
      principal_id = var.ops_team_group_id
      description  = "Operations team Container Apps access"
    }
  }
}
```

### ABAC Conditions

```hcl
module "rbac" {
  source = "../../azure/rbac-baseline"
  
  role_assignments = {
    storage_restricted = {
      scope        = azurerm_storage_account.main.id
      role_name    = "Storage Blob Data Reader"
      principal_id = var.app_principal_id
      
      # Only allow access to blobs tagged with environment=prod
      condition = <<-EOT
        (
          @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'prod-data'
        )
      EOT
      condition_version = "2.0"
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
| managed_identities | Map of user-assigned managed identities to create | `map(object)` | `{}` | no |
| role_assignments | Map of role assignments to create | `map(object)` | `{}` | no |
| custom_roles | Map of custom role definitions | `map(object)` | `{}` | no |
| identity_role_assignments | Role assignments for identities created by this module | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| managed_identities | Map of created managed identities with full details |
| identity_ids | Map of identity keys to resource IDs |
| identity_principal_ids | Map of identity keys to principal IDs |
| identity_client_ids | Map of identity keys to client IDs |
| role_assignments | Map of created role assignments |
| custom_roles | Map of created custom role definitions |
| custom_role_ids | Map of custom role keys to role definition IDs |

## Common Built-in Roles

| Role | Use Case |
|------|----------|
| Key Vault Secrets User | Read secrets (apps) |
| Key Vault Secrets Officer | Manage secrets (admins) |
| Storage Blob Data Contributor | Read/write blobs |
| Storage Blob Data Reader | Read-only blob access |
| SQL DB Contributor | Manage SQL databases |
| Monitoring Contributor | Configure monitoring |
| Network Contributor | Manage networking |

## Security Considerations

### Do

- ✅ Use managed identities for all Azure service authentication
- ✅ Create custom roles with minimal required permissions
- ✅ Use ABAC conditions for fine-grained access when needed
- ✅ Assign roles at the narrowest scope possible

### Don't

- ❌ Never use service principals with client secrets in production
- ❌ Avoid Owner role unless absolutely necessary
- ❌ Don't assign roles at subscription level when resource group suffices
- ❌ Don't use Key Vault access policies (use RBAC mode)

## License

MIT
