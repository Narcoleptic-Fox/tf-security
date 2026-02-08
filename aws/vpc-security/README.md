# VPC Security Module

Security groups and NACLs for AWS VPCs.

## Planned Features

- [ ] Default security group (locked down)
- [ ] Web tier SG (HTTP/HTTPS ingress)
- [ ] App tier SG (internal only)
- [ ] Database tier SG (app tier only)
- [ ] Bastion SG (SSH with IP allowlist)
- [ ] VPC flow logs to CloudWatch/S3
- [ ] NACL templates

## Usage (Coming Soon)

```hcl
module "vpc_security" {
  source = "github.com/Narcoleptic-Fox/tf-security//aws/vpc-security"

  vpc_id        = module.vpc.vpc_id
  naming_prefix = module.naming.prefix
  tags          = module.tags.common_tags
}
```
