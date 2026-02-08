# 🦊 tf-security

**Terraform security baseline modules for AWS and Azure**

Part of the [Narcoleptic Fox](https://github.com/Narcoleptic-Fox) infrastructure toolkit.

## Overview

Shared security patterns that every project needs:
- **Naming conventions** — Consistent resource names across clouds
- **Tagging standards** — Required tags for cost tracking, ownership, compliance
- **Security baselines** — IAM/RBAC, encryption, logging, threat detection

## Quick Start

Add as a git submodule:

```bash
git submodule add https://github.com/Narcoleptic-Fox/tf-security.git modules/tf-security
```

## Modules

### Core (Cloud-Agnostic)

| Module | Description |
|--------|-------------|
| [`core/naming`](./core/naming/) | Generate standardized resource names |
| [`core/tagging`](./core/tagging/) | Required tags for all resources |

### AWS Security

| Module | Description |
|--------|-------------|
| [`aws/iam-baseline`](./aws/iam-baseline/) | Least-privilege IAM roles and policies |
| [`aws/vpc-security`](./aws/vpc-security/) | Security groups, NACLs |
| [`aws/encryption`](./aws/encryption/) | KMS keys and encryption defaults |
| [`aws/logging`](./aws/logging/) | CloudTrail, CloudWatch configuration |
| [`aws/guardduty`](./aws/guardduty/) | Threat detection setup |

### Azure Security

| Module | Description |
|--------|-------------|
| [`azure/rbac-baseline`](./azure/rbac-baseline/) | Role assignments and custom roles |
| [`azure/network-security`](./azure/network-security/) | NSGs, ASGs |
| [`azure/encryption`](./azure/encryption/) | Key Vault, customer-managed keys |
| [`azure/logging`](./azure/logging/) | Azure Monitor, Log Analytics |
| [`azure/defender`](./azure/defender/) | Microsoft Defender for Cloud |

## Usage Example

```hcl
module "naming" {
  source      = "./modules/tf-security/core/naming"
  environment = "prod"
  project     = "mousing"
  region      = "us-east-1"
}

module "tags" {
  source      = "./modules/tf-security/core/tagging"
  environment = "prod"
  project     = "mousing"
  owner       = "platform-team"
  cost_center = "engineering"
}

# Use in your resources
resource "aws_s3_bucket" "data" {
  bucket = module.naming.s3_bucket_name
  tags   = module.tags.common_tags
}
```

## Conventions

See [`core/conventions.md`](./core/conventions.md) for human-readable standards.

## Related Repos

- [tf-aws](https://github.com/Narcoleptic-Fox/tf-aws) — AWS infrastructure modules
- [tf-azure](https://github.com/Narcoleptic-Fox/tf-azure) — Azure infrastructure modules

## License

MIT — See [LICENSE](./LICENSE)
