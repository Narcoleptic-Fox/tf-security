# Encryption Module

Provides KMS key management and encryption configuration for AWS resources.
Follows AWS security best practices for key management and S3 encryption.

## Features

- **Customer-Managed KMS Key** - With automatic rotation enabled
- **Flexible Key Policies** - Admin, user, and service principal access
- **S3 Encryption Defaults** - Secure bucket with enforced encryption
- **Cross-Account Support** - Allow key usage from other accounts

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

  # Key configuration
  enable_key_rotation     = true
  deletion_window_in_days = 30

  # Service access
  enable_cloudwatch_logs = true
  enable_s3              = true
  enable_secrets_manager = true
  enable_ssm             = true

  # Key users (IAM roles that can encrypt/decrypt)
  key_user_arns = [
    module.iam_baseline.lambda_role_arn,
    module.iam_baseline.ecs_task_role_arn,
  ]

  # Create a secure S3 bucket
  create_secure_bucket     = true
  enable_bucket_versioning = true
  enable_lifecycle_rules   = true

  tags = module.tagging.common_tags
}

# Use the KMS key for RDS encryption
resource "aws_db_instance" "main" {
  # ...
  storage_encrypted = true
  kms_key_id        = module.encryption.kms_key_arn
}

# Use the KMS key for CloudWatch Logs
resource "aws_cloudwatch_log_group" "app" {
  name       = "/app/myapp"
  kms_key_id = module.encryption.kms_key_arn
}
```

## Key Policy Structure

The module creates a comprehensive key policy with the following structure:

1. **Root Account Access** - Full access for account root (AWS best practice)
2. **Key Administrators** - Can manage key but not use it for encryption
3. **Key Users** - Can encrypt/decrypt but not manage key
4. **Service Principals** - AWS services that need key access
5. **Cross-Account** - External accounts with usage permissions

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| enable_key_rotation | Enable automatic key rotation | `bool` | `true` | no |
| deletion_window_in_days | Days before key deletion | `number` | `30` | no |
| key_admin_arns | IAM principals for key admin | `list(string)` | `[]` | no |
| key_user_arns | IAM principals for key usage | `list(string)` | `[]` | no |
| enable_cloudwatch_logs | Allow CloudWatch Logs access | `bool` | `true` | no |
| enable_s3 | Allow S3 service access | `bool` | `true` | no |
| create_secure_bucket | Create encrypted S3 bucket | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| kms_key_id | ID of the KMS key |
| kms_key_arn | ARN of the KMS key |
| kms_alias_name | Primary alias name |
| bucket_arn | ARN of secure S3 bucket |
| bucket_name | Name of secure S3 bucket |

## S3 Bucket Security

When `create_secure_bucket = true`, the bucket is configured with:

- ✅ All public access blocked
- ✅ Server-side encryption with KMS (required)
- ✅ HTTPS-only access enforced
- ✅ Versioning enabled
- ✅ Lifecycle rules for cost optimization
- ✅ Bucket Key enabled for reduced KMS costs

## Security Considerations

- Key rotation is enabled by default (rotates every year)
- 30-day deletion window protects against accidental deletion
- Service principals are scoped to caller account only
- S3 bucket policy denies unencrypted uploads
- No public access possible for S3 bucket

## License

Apache 2.0
