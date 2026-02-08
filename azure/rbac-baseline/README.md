# RBAC Baseline Module

Azure role assignments and custom role definitions.

## Planned Features

- [ ] Reader role for monitoring
- [ ] Contributor role for deployment
- [ ] Custom least-privilege roles
- [ ] Managed identity templates
- [ ] Service principal with certificate auth
- [ ] Conditional access integration

## Usage (Coming Soon)

```hcl
module "rbac" {
  source = "github.com/Narcoleptic-Fox/tf-security//azure/rbac-baseline"

  resource_group_id = azurerm_resource_group.main.id
  naming_prefix     = module.naming.prefix
  tags              = module.tags.azure_tags
}
```
