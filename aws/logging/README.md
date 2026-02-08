# Logging Module

Provides centralized logging infrastructure for AWS accounts including CloudTrail,
CloudWatch Log Groups, and security monitoring with metric filters and alarms.

## Features

- **CloudTrail** - Multi-region trail with S3 and CloudWatch destinations
- **CloudWatch Log Groups** - Application logs with configurable retention
- **Security Monitoring** - CIS benchmark metric filters and alarms
- **Cost Optimization** - Lifecycle rules for log archival

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

module "encryption" {
  source = "../../aws/encryption"

  name_prefix = module.naming.prefix
  tags        = module.tagging.common_tags
}

module "logging" {
  source = "../../aws/logging"

  name_prefix = module.naming.prefix

  # CloudTrail configuration
  create_cloudtrail             = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_cloudwatch_logs        = true
  cloudtrail_log_retention_days = 90
  kms_key_arn                   = module.encryption.kms_key_arn

  # Data events (optional, adds cost)
  enable_data_events    = true
  data_event_s3_buckets = ["arn:aws:s3"]  # All buckets

  # Application log groups
  application_log_groups = {
    app = {
      name           = "/app/${module.naming.prefix}"
      retention_days = 30
    }
    lambda = {
      name           = "/aws/lambda/${module.naming.prefix}"
      retention_days = 14
    }
  }

  # Security monitoring
  enable_security_metric_filters = true
  enable_security_alarms         = true
  alarm_sns_topic_arns           = [aws_sns_topic.security.arn]

  tags = module.tagging.common_tags
}
```

## Security Metric Filters

The module creates CIS AWS Foundations Benchmark metric filters for:

| Filter | Description |
|--------|-------------|
| UnauthorizedAPICalls | Unauthorized or access denied API calls |
| ConsoleSignInWithoutMFA | Console logins without MFA |
| RootAccountUsage | Root account API activity |
| IAMPolicyChanges | IAM policy modifications |
| CloudTrailConfigChanges | CloudTrail configuration changes |
| ConsoleSignInFailures | Failed console authentication |
| DisableOrDeleteCMK | KMS key disable or deletion |
| S3BucketPolicyChanges | S3 bucket policy modifications |
| SecurityGroupChanges | Security group modifications |
| NACLChanges | Network ACL modifications |
| VPCChanges | VPC configuration changes |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| kms_key_arn | KMS key for encryption | `string` | `null` | no |
| create_cloudtrail | Create CloudTrail trail | `bool` | `true` | no |
| is_multi_region_trail | Multi-region trail | `bool` | `true` | no |
| enable_cloudwatch_logs | Send to CloudWatch | `bool` | `true` | no |
| enable_data_events | Log S3/Lambda data events | `bool` | `false` | no |
| application_log_groups | App log groups to create | `map(object)` | `{}` | no |
| enable_security_metric_filters | Create security metrics | `bool` | `true` | no |
| enable_security_alarms | Create security alarms | `bool` | `true` | no |
| alarm_sns_topic_arns | SNS topics for alarms | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudtrail_arn | ARN of CloudTrail trail |
| cloudtrail_bucket_arn | ARN of CloudTrail S3 bucket |
| cloudtrail_log_group_arn | ARN of CloudTrail Log Group |
| application_log_groups | Map of app log group ARNs |
| security_alarm_arns | Map of security alarm ARNs |

## Cost Considerations

- **Data Events** - S3/Lambda data events add significant cost. Enable only when needed.
- **Log Retention** - Shorter retention reduces costs
- **Lifecycle Rules** - Transition to IA/Glacier for cost savings
- **Metric Filters** - No additional cost
- **Alarms** - Minimal cost (~$0.10/alarm/month)

## Security Considerations

- CloudTrail log file validation enabled
- S3 bucket blocks all public access
- HTTPS-only access enforced
- KMS encryption supported
- Multi-region trail captures all regions
- CIS benchmark metric filters included

## License

Apache 2.0
