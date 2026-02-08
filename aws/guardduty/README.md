# GuardDuty Module

AWS GuardDuty threat detection setup.

## Planned Features

- [ ] GuardDuty detector
- [ ] S3 protection
- [ ] EKS protection
- [ ] Malware protection
- [ ] SNS notifications
- [ ] Finding aggregation

## Usage (Coming Soon)

```hcl
module "guardduty" {
  source = "github.com/Narcoleptic-Fox/tf-security//aws/guardduty"

  naming_prefix     = module.naming.prefix
  notification_arns = [aws_sns_topic.security.arn]
  tags              = module.tags.common_tags
}
```
