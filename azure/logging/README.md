# Logging Module

Azure Monitor and Log Analytics configuration.

## Planned Features

- [ ] Log Analytics Workspace
- [ ] Diagnostic settings template
- [ ] Activity Log export
- [ ] Resource health alerts
- [ ] Metric alerts for security
- [ ] Action groups for notifications

## Usage (Coming Soon)

```hcl
module "logging" {
  source = "github.com/Narcoleptic-Fox/tf-security//azure/logging"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  naming_prefix       = module.naming.prefix
  tags                = module.tags.azure_tags
}

# Attach to resources
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "diag-vnet"
  target_resource_id         = azurerm_virtual_network.main.id
  log_analytics_workspace_id = module.logging.workspace_id
}
```
