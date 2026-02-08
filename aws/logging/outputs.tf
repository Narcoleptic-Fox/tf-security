# -----------------------------------------------------------------------------
# CloudTrail Outputs
# -----------------------------------------------------------------------------

output "cloudtrail_id" {
  description = "ID of the CloudTrail trail"
  value       = try(aws_cloudtrail.main[0].id, null)
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = try(aws_cloudtrail.main[0].arn, null)
}

output "cloudtrail_home_region" {
  description = "Home region of the CloudTrail trail"
  value       = try(aws_cloudtrail.main[0].home_region, null)
}

# -----------------------------------------------------------------------------
# CloudTrail S3 Bucket Outputs
# -----------------------------------------------------------------------------

output "cloudtrail_bucket_id" {
  description = "ID of the CloudTrail S3 bucket"
  value       = try(aws_s3_bucket.cloudtrail[0].id, null)
}

output "cloudtrail_bucket_arn" {
  description = "ARN of the CloudTrail S3 bucket"
  value       = try(aws_s3_bucket.cloudtrail[0].arn, null)
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket"
  value       = try(aws_s3_bucket.cloudtrail[0].bucket, null)
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group Outputs
# -----------------------------------------------------------------------------

output "cloudtrail_log_group_arn" {
  description = "ARN of the CloudTrail CloudWatch Log Group"
  value       = try(aws_cloudwatch_log_group.cloudtrail[0].arn, null)
}

output "cloudtrail_log_group_name" {
  description = "Name of the CloudTrail CloudWatch Log Group"
  value       = try(aws_cloudwatch_log_group.cloudtrail[0].name, null)
}

output "application_log_groups" {
  description = "Map of application log group ARNs"
  value = {
    for k, v in aws_cloudwatch_log_group.application : k => {
      arn  = v.arn
      name = v.name
    }
  }
}

# -----------------------------------------------------------------------------
# Security Monitoring Outputs
# -----------------------------------------------------------------------------

output "security_metric_filter_names" {
  description = "Names of security metric filters created"
  value       = [for k, v in aws_cloudwatch_log_metric_filter.security_events : k]
}

output "security_alarm_arns" {
  description = "ARNs of security CloudWatch alarms"
  value = {
    for k, v in aws_cloudwatch_metric_alarm.security_events : k => v.arn
  }
}

output "metric_namespace" {
  description = "CloudWatch metric namespace for security metrics"
  value       = var.metric_namespace
}
