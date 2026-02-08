# -----------------------------------------------------------------------------
# GuardDuty Detector Outputs
# -----------------------------------------------------------------------------

output "detector_id" {
  description = "ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}

output "detector_arn" {
  description = "ARN of the GuardDuty detector"
  value       = aws_guardduty_detector.main.arn
}

output "account_id" {
  description = "AWS account ID where GuardDuty is enabled"
  value       = aws_guardduty_detector.main.account_id
}

# -----------------------------------------------------------------------------
# SNS Topic Outputs
# -----------------------------------------------------------------------------

output "sns_topic_arn" {
  description = "ARN of the SNS topic for findings"
  value       = try(aws_sns_topic.findings[0].arn, null)
}

output "sns_topic_name" {
  description = "Name of the SNS topic for findings"
  value       = try(aws_sns_topic.findings[0].name, null)
}

# -----------------------------------------------------------------------------
# EventBridge Outputs
# -----------------------------------------------------------------------------

output "findings_event_rule_arn" {
  description = "ARN of the EventBridge rule for findings"
  value       = try(aws_cloudwatch_event_rule.findings[0].arn, null)
}

output "high_severity_event_rule_arn" {
  description = "ARN of the EventBridge rule for high severity findings"
  value       = try(aws_cloudwatch_event_rule.high_severity[0].arn, null)
}

# -----------------------------------------------------------------------------
# Filter Outputs
# -----------------------------------------------------------------------------

output "suppression_filter_ids" {
  description = "Map of suppression filter IDs"
  value = {
    for k, v in aws_guardduty_filter.suppression : k => v.id
  }
}

# -----------------------------------------------------------------------------
# IP/Intel Set Outputs
# -----------------------------------------------------------------------------

output "trusted_ip_set_id" {
  description = "ID of the trusted IP set"
  value       = try(aws_guardduty_ipset.trusted[0].id, null)
}

output "threat_intel_set_id" {
  description = "ID of the threat intelligence set"
  value       = try(aws_guardduty_threatintelset.custom[0].id, null)
}
