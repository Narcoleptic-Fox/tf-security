# Tagging Module

Enforces required tags for all resources across AWS and Azure.

## Required Tags

| Tag | Description |
|-----|-------------|
| `Environment` | dev, staging, prod |
| `Project` | Project/product name |
| `Owner` | Responsible team or individual |
| `CostCenter` | Billing allocation code |
| `ManagedBy` | Always "terraform" |
| `CreatedAt` | Creation timestamp |

## Usage

```hcl
module "tags" {
  source = "github.com/Narcoleptic-Fox/tf-security//core/tagging"

  environment = "prod"
  project     = "mousing"
  owner       = "platform-team"
  cost_center = "engineering"

  # Optional
  application = "data-pipeline"
  team        = "data-engineering"
  repository  = "github.com/Narcoleptic-Fox/mousing"
  compliance  = "SOC2"
}

# Use in AWS resources
resource "aws_s3_bucket" "data" {
  bucket = "my-bucket"
  tags   = module.tags.common_tags
}

# Use in Azure resources
resource "azurerm_resource_group" "main" {
  name     = "rg-example"
  location = "eastus"
  tags     = module.tags.azure_tags
}
```

## Inputs

### Required

| Name | Description |
|------|-------------|
| `environment` | Environment (dev/staging/prod) |
| `project` | Project name |
| `owner` | Responsible party |
| `cost_center` | Billing code |

### Optional

| Name | Description |
|------|-------------|
| `application` | Application name |
| `team` | Team name |
| `repository` | Repo URL |
| `compliance` | Compliance framework |
| `extra_tags` | Additional custom tags |

## Outputs

| Name | Description |
|------|-------------|
| `common_tags` | Complete tag map |
| `required_tags` | Only required tags |
| `aws_tags` | AWS-formatted tags |
| `aws_asg_tags` | ASG propagate-at-launch format |
| `azure_tags` | Azure-formatted tags |
