# GuardDuty Module

Provides AWS GuardDuty threat detection with comprehensive monitoring and notification capabilities.

## Features

- **Threat Detection** - CloudTrail, VPC Flow Logs, and DNS analysis
- **S3 Protection** - Monitors S3 data access events
- **Kubernetes Protection** - EKS audit log monitoring
- **Malware Protection** - EBS volume scanning
- **Runtime Monitoring** - Container workload protection
- **SNS Notifications** - Email alerts for findings
- **EventBridge Integration** - Custom event routing

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
  owner       = "security-team"
  cost_center = "security"
}

module "encryption" {
  source = "../../aws/encryption"

  name_prefix = module.naming.prefix
  tags        = module.tagging.common_tags
}

module "guardduty" {
  source = "../../aws/guardduty"

  name_prefix = module.naming.prefix

  # Protection features
  enable_s3_protection         = true
  enable_kubernetes_protection = true
  enable_malware_protection    = true
  enable_lambda_protection     = true
  enable_rds_protection        = true

  # Runtime monitoring (for containers)
  enable_runtime_monitoring     = true
  enable_eks_runtime_monitoring = true
  enable_ecs_runtime_monitoring = true

  # Notifications
  create_sns_topic             = true
  sns_kms_key_arn              = module.encryption.kms_key_arn
  notification_email_addresses = ["security@example.com"]

  # EventBridge
  enable_eventbridge_notifications = true
  min_severity_for_notification    = 4  # Medium and above
  enable_high_severity_alert       = true

  # Suppression filters for known false positives
  suppression_filters = {
    "suppress-internal-scanner" = {
      rank = 1
      criteria = [
        {
          field  = "service.action.networkConnectionAction.remoteIpDetails.ipAddressV4"
          equals = ["10.0.0.100"]  # Internal security scanner
        }
      ]
    }
  }

  tags = module.tagging.common_tags
}
```

## Finding Severity Levels

| Severity | Range | Description |
|----------|-------|-------------|
| Low | 1.0 - 3.9 | Suspicious activity that may not pose immediate risk |
| Medium | 4.0 - 6.9 | Suspicious activity that deviates from normal behavior |
| High | 7.0 - 8.9 | Resource is compromised and actively being used for malicious purposes |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| enable_s3_protection | Monitor S3 data access | `bool` | `true` | no |
| enable_kubernetes_protection | Monitor EKS audit logs | `bool` | `true` | no |
| enable_malware_protection | Scan EBS volumes | `bool` | `true` | no |
| enable_runtime_monitoring | Container runtime protection | `bool` | `false` | no |
| enable_lambda_protection | Lambda network monitoring | `bool` | `false` | no |
| enable_rds_protection | RDS login monitoring | `bool` | `false` | no |
| create_sns_topic | Create SNS topic for alerts | `bool` | `true` | no |
| notification_email_addresses | Emails to notify | `list(string)` | `[]` | no |
| min_severity_for_notification | Min severity for alerts | `number` | `4` | no |
| suppression_filters | Filters for false positives | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| detector_id | GuardDuty detector ID |
| detector_arn | GuardDuty detector ARN |
| sns_topic_arn | SNS topic ARN for findings |
| findings_event_rule_arn | EventBridge rule ARN |

## Cost Considerations

- **Base Cost** - GuardDuty charges based on CloudTrail events and VPC Flow Logs analyzed
- **S3 Protection** - Additional cost based on S3 data events
- **Malware Protection** - Charges for EBS volume scans
- **Runtime Monitoring** - Per-vCPU hour charges for monitored containers
- **Free Trial** - 30-day free trial for new accounts

## Security Considerations

- All protection features enabled by default where no additional cost
- SNS topic encrypted with KMS
- High severity findings trigger separate alerts
- Suppression filters for known false positives
- Trusted IP lists supported for internal scanners
- Custom threat intelligence integration available

## Multi-Account Setup

For AWS Organizations, consider using:
- GuardDuty Organization Admin account
- `aws_guardduty_organization_admin_account`
- `aws_guardduty_organization_configuration`
- Member account auto-enable

## License

Apache 2.0
