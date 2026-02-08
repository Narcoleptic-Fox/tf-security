/**
 * # Tagging Module
 *
 * Enforces required tags for all resources.
 * Required tags: environment, project, owner, cost_center
 * 
 * Outputs tag maps ready for AWS and Azure resources.
 */

locals {
  # Timestamp for creation tracking
  created_at = formatdate("YYYY-MM-DD", timestamp())

  # Required tags (always present)
  required_tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    CreatedAt   = local.created_at
  }

  # Optional tags (only if provided)
  optional_tags = {
    for k, v in {
      Application = var.application
      Team        = var.team
      Repository  = var.repository
      Compliance  = var.compliance
    } : k => v if v != null && v != ""
  }

  # Merged tag map
  common_tags = merge(local.required_tags, local.optional_tags, var.extra_tags)
}
