# Logging Module

CloudTrail and CloudWatch configuration for AWS.

## Planned Features

- [ ] Multi-region CloudTrail
- [ ] CloudTrail to S3 with encryption
- [ ] CloudWatch Log Groups with retention
- [ ] Metric filters for security events
- [ ] SNS alerts for critical events
- [ ] Config rules integration

## Usage (Coming Soon)

```hcl
module "logging" {
  source = "github.com/Narcoleptic-Fox/tf-security//aws/logging"

  naming_prefix = module.naming.prefix
  kms_key_arn   = module.encryption.cloudtrail_key_arn
  tags          = module.tags.common_tags
}
```
