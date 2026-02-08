# Defender Module

Microsoft Defender for Cloud setup.

## Planned Features

- [ ] Defender plans (VMs, Storage, SQL, etc.)
- [ ] Security contacts
- [ ] Auto-provisioning
- [ ] Secure score monitoring
- [ ] Regulatory compliance
- [ ] Continuous export to Log Analytics

## Usage (Coming Soon)

```hcl
module "defender" {
  source = "github.com/Narcoleptic-Fox/tf-security//azure/defender"

  security_contact_email = "security@narcoleptic.fox"
  log_analytics_id       = module.logging.workspace_id
  tags                   = module.tags.azure_tags
}
```
