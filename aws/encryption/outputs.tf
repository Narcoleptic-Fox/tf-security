# -----------------------------------------------------------------------------
# KMS Key Outputs
# -----------------------------------------------------------------------------

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "kms_alias_name" {
  description = "Name of the primary KMS alias"
  value       = aws_kms_alias.main.name
}

output "kms_alias_arn" {
  description = "ARN of the primary KMS alias"
  value       = aws_kms_alias.main.arn
}

output "kms_key_policy" {
  description = "The key policy of the KMS key"
  value       = aws_kms_key.main.policy
}

# -----------------------------------------------------------------------------
# S3 Bucket Outputs
# -----------------------------------------------------------------------------

output "bucket_id" {
  description = "ID of the secure S3 bucket"
  value       = try(aws_s3_bucket.secure[0].id, null)
}

output "bucket_arn" {
  description = "ARN of the secure S3 bucket"
  value       = try(aws_s3_bucket.secure[0].arn, null)
}

output "bucket_name" {
  description = "Name of the secure S3 bucket"
  value       = try(aws_s3_bucket.secure[0].bucket, null)
}

output "bucket_domain_name" {
  description = "Domain name of the secure S3 bucket"
  value       = try(aws_s3_bucket.secure[0].bucket_domain_name, null)
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the secure S3 bucket"
  value       = try(aws_s3_bucket.secure[0].bucket_regional_domain_name, null)
}
