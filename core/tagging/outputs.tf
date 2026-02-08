output "common_tags" {
  description = "Complete tag map for all resources"
  value       = local.common_tags
}

output "required_tags" {
  description = "Only the required tags"
  value       = local.required_tags
}

# AWS-specific outputs
output "aws_tags" {
  description = "Tags formatted for AWS resources"
  value       = local.common_tags
}

output "aws_asg_tags" {
  description = "Tags formatted for AWS Auto Scaling Groups (propagate_at_launch)"
  value = [
    for k, v in local.common_tags : {
      key                 = k
      value               = v
      propagate_at_launch = true
    }
  ]
}

# Azure-specific outputs
output "azure_tags" {
  description = "Tags formatted for Azure resources"
  value       = local.common_tags
}

# Individual tag values (for interpolation)
output "environment" {
  description = "Environment tag value"
  value       = var.environment
}

output "project" {
  description = "Project tag value"
  value       = var.project
}

output "owner" {
  description = "Owner tag value"
  value       = var.owner
}

output "cost_center" {
  description = "CostCenter tag value"
  value       = var.cost_center
}
