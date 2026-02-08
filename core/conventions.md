# Infrastructure Conventions

Human-readable standards for Narcoleptic Fox infrastructure.

## Naming

### Pattern
```
{project}-{environment}-{region}-{resource}
```

### Examples
- VPC: `mousing-prod-use1-vpc`
- S3 bucket: `mousing-prod-use1-data`
- IAM role: `mousing-prod-use1-role-lambda`

### Rules
1. All lowercase
2. Hyphens as separators (no underscores)
3. Max 63 characters (DNS-safe)
4. Project name comes first for easy sorting

## Tagging

### Required Tags

Every resource MUST have:

| Tag | Purpose | Example |
|-----|---------|---------|
| `Environment` | Deployment stage | `prod`, `staging`, `dev` |
| `Project` | Product/project name | `mousing` |
| `Owner` | Responsible team | `platform-team` |
| `CostCenter` | Billing allocation | `engineering` |
| `ManagedBy` | IaC tool | `terraform` |

### Optional Tags

| Tag | Purpose |
|-----|---------|
| `Application` | App within project |
| `Team` | Sub-team |
| `Repository` | Source repo URL |
| `Compliance` | Regulatory framework |

## Environments

| Name | Code | Purpose |
|------|------|---------|
| `development` | `dev` | Local/sandbox testing |
| `staging` | `stg` | Pre-production |
| `production` | `prod` | Live traffic |
| `test` | `tst` | CI/integration tests |

## Security Baselines

### AWS
- [ ] No public S3 buckets (unless explicitly CDN)
- [ ] Default encryption (KMS) on all storage
- [ ] VPC flow logs enabled
- [ ] CloudTrail in all regions
- [ ] GuardDuty enabled
- [ ] IMDSv2 required on EC2
- [ ] Security groups: explicit allow, default deny

### Azure
- [ ] Storage accounts private by default
- [ ] CMK encryption via Key Vault
- [ ] NSG flow logs enabled
- [ ] Diagnostic settings to Log Analytics
- [ ] Defender for Cloud enabled
- [ ] Managed identities over service principals

## Branch Strategy

| Branch | Environment | Deploys to |
|--------|-------------|------------|
| `main` | production | prod |
| `staging` | staging | staging |
| `dev` | development | dev |

Feature branches merge to `dev` → `staging` → `main`.
