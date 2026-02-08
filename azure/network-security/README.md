# Network Security Module

Azure NSGs and Application Security Groups.

## Planned Features

- [ ] Default NSG (deny all inbound)
- [ ] Web tier NSG (HTTP/HTTPS)
- [ ] App tier NSG (internal only)
- [ ] Database tier NSG (app tier only)
- [ ] Bastion NSG
- [ ] NSG flow logs
- [ ] Application Security Groups

## Usage (Coming Soon)

```hcl
module "network_security" {
  source = "github.com/Narcoleptic-Fox/tf-security//azure/network-security"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  naming_prefix       = module.naming.prefix
  tags                = module.tags.azure_tags
}
```
