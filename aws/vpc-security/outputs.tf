# -----------------------------------------------------------------------------
# Security Group Outputs
# -----------------------------------------------------------------------------

output "web_security_group_id" {
  description = "ID of the web tier security group"
  value       = try(aws_security_group.web[0].id, null)
}

output "web_security_group_arn" {
  description = "ARN of the web tier security group"
  value       = try(aws_security_group.web[0].arn, null)
}

output "app_security_group_id" {
  description = "ID of the application tier security group"
  value       = try(aws_security_group.app[0].id, null)
}

output "app_security_group_arn" {
  description = "ARN of the application tier security group"
  value       = try(aws_security_group.app[0].arn, null)
}

output "db_security_group_id" {
  description = "ID of the database tier security group"
  value       = try(aws_security_group.db[0].id, null)
}

output "db_security_group_arn" {
  description = "ARN of the database tier security group"
  value       = try(aws_security_group.db[0].arn, null)
}

output "security_group_ids" {
  description = "Map of all security group IDs by tier"
  value = {
    web = try(aws_security_group.web[0].id, null)
    app = try(aws_security_group.app[0].id, null)
    db  = try(aws_security_group.db[0].id, null)
  }
}

# -----------------------------------------------------------------------------
# NACL Outputs
# -----------------------------------------------------------------------------

output "public_nacl_id" {
  description = "ID of the public subnet NACL"
  value       = try(aws_network_acl.public[0].id, null)
}

output "public_nacl_arn" {
  description = "ARN of the public subnet NACL"
  value       = try(aws_network_acl.public[0].arn, null)
}

output "private_nacl_id" {
  description = "ID of the private subnet NACL"
  value       = try(aws_network_acl.private[0].id, null)
}

output "private_nacl_arn" {
  description = "ARN of the private subnet NACL"
  value       = try(aws_network_acl.private[0].arn, null)
}

# -----------------------------------------------------------------------------
# Flow Log Outputs
# -----------------------------------------------------------------------------

output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = try(aws_flow_log.main[0].id, null)
}

output "flow_log_arn" {
  description = "ARN of the VPC Flow Log"
  value       = try(aws_flow_log.main[0].arn, null)
}

output "flow_log_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for flow logs"
  value       = try(aws_cloudwatch_log_group.flow_logs[0].arn, null)
}

output "flow_log_role_arn" {
  description = "ARN of the IAM role for flow logs"
  value       = try(aws_iam_role.flow_logs[0].arn, null)
}
