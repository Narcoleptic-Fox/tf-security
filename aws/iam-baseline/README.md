# IAM Baseline Module

Provides least-privilege IAM patterns for common AWS services. This module creates
secure, pre-configured IAM roles following AWS security best practices.

## Features

- **Lambda Execution Role** - CloudWatch Logs access with optional X-Ray and VPC
- **ECS Task Roles** - Separate task and execution roles with secrets access
- **EC2 Instance Profile** - SSM Session Manager and CloudWatch Agent
- **Cross-Account Role** - Secure assume role with external ID support

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

module "iam_baseline" {
  source = "../../aws/iam-baseline"

  name_prefix = module.naming.prefix

  # Lambda role with VPC access
  create_lambda_role       = true
  enable_lambda_vpc_access = true
  enable_xray_tracing      = true

  # ECS roles with secrets
  create_ecs_task_role = true
  ecs_secret_arns = [
    "arn:aws:secretsmanager:us-east-1:123456789:secret:myapp/*"
  ]

  # EC2 with SSM
  create_ec2_ssm_role   = true
  enable_ec2_cloudwatch = true

  # Cross-account access (optional)
  create_cross_account_role = true
  trusted_account_ids       = ["987654321012"]
  require_external_id       = true
  external_id               = var.external_id
  cross_account_purpose     = "CI/CD deployment"
  cross_account_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "arn:aws:s3:::deployment-bucket/*"
    }]
  })

  tags = module.tagging.common_tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for all IAM resource names | `string` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |
| create_lambda_role | Create Lambda execution role | `bool` | `true` | no |
| enable_xray_tracing | Enable X-Ray tracing for Lambda | `bool` | `false` | no |
| enable_lambda_vpc_access | Enable VPC access for Lambda | `bool` | `false` | no |
| create_ecs_task_role | Create ECS task and execution roles | `bool` | `true` | no |
| ecs_secret_arns | Secret ARNs for ECS task access | `list(string)` | `[]` | no |
| ecs_ssm_parameter_arns | SSM Parameter ARNs for ECS | `list(string)` | `[]` | no |
| create_ec2_ssm_role | Create EC2 instance profile with SSM | `bool` | `true` | no |
| enable_ec2_cloudwatch | Enable CloudWatch Agent for EC2 | `bool` | `true` | no |
| create_cross_account_role | Create cross-account assume role | `bool` | `false` | no |
| trusted_account_ids | Account IDs allowed to assume role | `list(string)` | `[]` | no |
| require_external_id | Require external ID for assume role | `bool` | `true` | no |
| external_id | External ID for cross-account access | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| lambda_role_arn | ARN of the Lambda execution role |
| lambda_role_name | Name of the Lambda execution role |
| ecs_task_role_arn | ARN of the ECS task role |
| ecs_execution_role_arn | ARN of the ECS execution role |
| ec2_instance_profile_arn | ARN of the EC2 instance profile |
| cross_account_role_arn | ARN of the cross-account role |

## Security Considerations

- All roles follow least-privilege principle
- CloudWatch Logs access is scoped to specific log groups
- Cross-account roles require external ID by default
- ECS execution role has separate, minimal permissions
- No wildcard resource permissions (except X-Ray which requires it)

## License

Apache 2.0
