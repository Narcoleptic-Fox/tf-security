# Naming Convention Module

Generates standardized resource names across AWS and Azure.

## Pattern

```
{project}-{environment}-{region_short}-{resource_type}
```

Example: `mousing-prod-use1-vpc`

## Usage

```hcl
module "naming" {
  source = "github.com/Narcoleptic-Fox/tf-security//core/naming"

  project     = "mousing"
  environment = "prod"
  region      = "us-east-1"
}

# Use generated names
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = module.naming.vpc_name  # mousing-prod-use1-vpc
  }
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project` | Project/product name | `string` | yes |
| `environment` | Environment (dev/staging/prod) | `string` | yes |
| `region` | Cloud region | `string` | yes |
| `suffix` | Optional suffix for uniqueness | `string` | no |

## Outputs

### Base
- `prefix` — Base naming prefix
- `project` — Normalized project name
- `environment` — Normalized environment code
- `region_code` — Short region code

### AWS
- `vpc_name`, `subnet_name`, `s3_bucket_name`
- `ec2_name`, `rds_name`, `lambda_name`
- `iam_role_name`, `security_group_name`, `kms_alias`

### Azure
- `resource_group_name`, `vnet_name`
- `storage_account_name`, `key_vault_name`
- `vm_name`, `nsg_name`

## Region Codes

| AWS Region | Code | Azure Region | Code |
|------------|------|--------------|------|
| us-east-1 | use1 | eastus | eus |
| us-west-2 | usw2 | westus2 | wus2 |
| eu-west-1 | euw1 | westeurope | weu |
| eu-central-1 | euc1 | northeurope | neu |
