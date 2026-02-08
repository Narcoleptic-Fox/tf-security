# VPC Security Module

Provides comprehensive network security controls for VPCs including security groups,
Network ACLs, and VPC Flow Logs.

## Features

- **Security Groups** - Three-tier architecture (web, app, database)
- **Network ACLs** - Public and private subnet controls
- **VPC Flow Logs** - CloudWatch or S3 destination with encryption support

## Usage

```hcl
module "naming" {
  source = "../../core/naming"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
}

module "tagging" {
  source = "../../core/tagging"

  environment = "prod"
  project     = "myapp"
  owner       = "platform-team"
  cost_center = "engineering"
}

module "vpc_security" {
  source = "../../aws/vpc-security"

  name_prefix = module.naming.prefix
  vpc_id      = aws_vpc.main.id
  vpc_cidr    = aws_vpc.main.cidr_block

  # Security Groups
  create_web_security_group = true
  create_app_security_group = true
  create_db_security_group  = true
  app_port                  = 8080
  db_port                   = 5432

  # NACLs
  create_public_nacl  = true
  create_private_nacl = true
  public_subnet_ids   = aws_subnet.public[*].id
  private_subnet_ids  = aws_subnet.private[*].id

  # Flow Logs to CloudWatch
  enable_flow_logs        = true
  flow_log_destination    = "cloud-watch-logs"
  flow_log_traffic_type   = "ALL"
  flow_log_retention_days = 30
  flow_log_kms_key_arn    = module.encryption.kms_key_arn

  tags = module.tagging.common_tags
}

# Use the security groups
resource "aws_lb" "main" {
  name               = "${module.naming.prefix}-alb"
  load_balancer_type = "application"
  security_groups    = [module.vpc_security.web_security_group_id]
  subnets            = aws_subnet.public[*].id
}
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                            VPC                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐  │
│  │   Public Subnet  │  │  Private Subnet  │  │   DB Subnet   │  │
│  │   (Web Tier)     │  │   (App Tier)     │  │  (Database)   │  │
│  │                  │  │                  │  │               │  │
│  │  ┌────────────┐  │  │  ┌────────────┐  │  │ ┌───────────┐ │  │
│  │  │ ALB/NLB    │──┼──┼─▶│ ECS/EC2    │──┼──┼─▶│ RDS/Aurora│ │  │
│  │  │ HTTPS:443  │  │  │  │ Port:8080  │  │  │ │ Port:5432 │ │  │
│  │  └────────────┘  │  │  └────────────┘  │  │ └───────────┘ │  │
│  │                  │  │                  │  │               │  │
│  │  NACL: Internet  │  │  NACL: VPC only  │  │   No egress   │  │
│  │  allowed         │  │  + NAT for HTTPS │  │               │  │
│  └──────────────────┘  └──────────────────┘  └───────────────┘  │
│                                                                  │
│  Flow Logs ───────────▶ CloudWatch / S3                         │
└─────────────────────────────────────────────────────────────────┘
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| vpc_cidr | CIDR block of the VPC | `string` | n/a | yes |
| create_web_security_group | Create web tier SG | `bool` | `true` | no |
| create_app_security_group | Create app tier SG | `bool` | `true` | no |
| create_db_security_group | Create database tier SG | `bool` | `true` | no |
| app_port | Application port | `number` | `8080` | no |
| db_port | Database port | `number` | `5432` | no |
| enable_flow_logs | Enable VPC Flow Logs | `bool` | `true` | no |
| flow_log_destination | Destination type | `string` | `"cloud-watch-logs"` | no |
| flow_log_retention_days | Log retention days | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| web_security_group_id | ID of web tier SG |
| app_security_group_id | ID of app tier SG |
| db_security_group_id | ID of database tier SG |
| security_group_ids | Map of all SG IDs |
| flow_log_id | ID of VPC Flow Log |
| flow_log_log_group_arn | CloudWatch Log Group ARN |

## Security Considerations

- Security groups use references instead of inline rules (better for changes)
- Database tier has no egress (isolated)
- NACLs provide defense-in-depth
- Flow logs capture all traffic by default
- CloudWatch logs can be encrypted with KMS
- No SSH/RDP rules (use SSM Session Manager instead)

## License

Apache 2.0
