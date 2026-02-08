# IAM Baseline Module

Least-privilege IAM role templates for common AWS services.

## Planned Features

- [ ] Lambda execution role with CloudWatch logs
- [ ] ECS task role template
- [ ] EC2 instance profile with SSM
- [ ] Cross-account assume role patterns
- [ ] Service-linked role references

## Usage (Coming Soon)

```hcl
module "iam" {
  source = "github.com/Narcoleptic-Fox/tf-security//aws/iam-baseline"

  naming_prefix = module.naming.prefix
  tags          = module.tags.common_tags
}
```
