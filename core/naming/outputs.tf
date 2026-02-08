# Base outputs
output "prefix" {
  description = "Base naming prefix: {project}-{env}-{region}"
  value       = local.prefix
}

output "project" {
  description = "Normalized project name"
  value       = local.project
}

output "environment" {
  description = "Normalized environment code"
  value       = local.environment
}

output "region_code" {
  description = "Short region code"
  value       = local.region
}

# AWS Resource Names
output "vpc_name" {
  description = "VPC name"
  value       = "${local.prefix}-vpc${var.suffix != "" ? "-${var.suffix}" : ""}"
}

output "subnet_name" {
  description = "Subnet name (append -public/-private and AZ)"
  value       = "${local.prefix}-subnet"
}

output "s3_bucket_name" {
  description = "S3 bucket name (globally unique, add random suffix in practice)"
  value       = "${local.prefix}-bucket${var.suffix != "" ? "-${var.suffix}" : ""}"
}

output "ec2_name" {
  description = "EC2 instance name prefix"
  value       = "${local.prefix}-ec2"
}

output "rds_name" {
  description = "RDS instance identifier"
  value       = "${local.prefix}-rds${var.suffix != "" ? "-${var.suffix}" : ""}"
}

output "lambda_name" {
  description = "Lambda function name prefix"
  value       = "${local.prefix}-fn"
}

output "iam_role_name" {
  description = "IAM role name prefix"
  value       = "${local.prefix}-role"
}

output "security_group_name" {
  description = "Security group name prefix"
  value       = "${local.prefix}-sg"
}

output "kms_alias" {
  description = "KMS key alias"
  value       = "alias/${local.prefix}"
}

# Azure Resource Names
output "resource_group_name" {
  description = "Azure resource group name"
  value       = "rg-${local.prefix}${var.suffix != "" ? "-${var.suffix}" : ""}"
}

output "vnet_name" {
  description = "Azure VNet name"
  value       = "vnet-${local.prefix}${var.suffix != "" ? "-${var.suffix}" : ""}"
}

output "storage_account_name" {
  description = "Azure storage account name (max 24 chars, no hyphens)"
  value       = substr(replace("st${local.project}${local.environment}${local.region}${var.suffix}", "-", ""), 0, 24)
}

output "key_vault_name" {
  description = "Azure Key Vault name (max 24 chars)"
  value       = substr("kv-${local.prefix}${var.suffix != "" ? "-${var.suffix}" : ""}", 0, 24)
}

output "vm_name" {
  description = "Azure VM name prefix"
  value       = "vm-${local.prefix}"
}

output "nsg_name" {
  description = "Azure NSG name"
  value       = "nsg-${local.prefix}"
}
