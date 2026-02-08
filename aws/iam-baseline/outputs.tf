# -----------------------------------------------------------------------------
# Lambda Role Outputs
# -----------------------------------------------------------------------------

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = try(aws_iam_role.lambda_execution[0].arn, null)
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = try(aws_iam_role.lambda_execution[0].name, null)
}

output "lambda_role_id" {
  description = "ID of the Lambda execution role"
  value       = try(aws_iam_role.lambda_execution[0].id, null)
}

# -----------------------------------------------------------------------------
# ECS Task Role Outputs
# -----------------------------------------------------------------------------

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = try(aws_iam_role.ecs_task[0].arn, null)
}

output "ecs_task_role_name" {
  description = "Name of the ECS task role"
  value       = try(aws_iam_role.ecs_task[0].name, null)
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = try(aws_iam_role.ecs_execution[0].arn, null)
}

output "ecs_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = try(aws_iam_role.ecs_execution[0].name, null)
}

# -----------------------------------------------------------------------------
# EC2 SSM Role Outputs
# -----------------------------------------------------------------------------

output "ec2_ssm_role_arn" {
  description = "ARN of the EC2 SSM role"
  value       = try(aws_iam_role.ec2_ssm[0].arn, null)
}

output "ec2_ssm_role_name" {
  description = "Name of the EC2 SSM role"
  value       = try(aws_iam_role.ec2_ssm[0].name, null)
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = try(aws_iam_instance_profile.ec2_ssm[0].arn, null)
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = try(aws_iam_instance_profile.ec2_ssm[0].name, null)
}

# -----------------------------------------------------------------------------
# Cross-Account Role Outputs
# -----------------------------------------------------------------------------

output "cross_account_role_arn" {
  description = "ARN of the cross-account role"
  value       = try(aws_iam_role.cross_account[0].arn, null)
}

output "cross_account_role_name" {
  description = "Name of the cross-account role"
  value       = try(aws_iam_role.cross_account[0].name, null)
}
