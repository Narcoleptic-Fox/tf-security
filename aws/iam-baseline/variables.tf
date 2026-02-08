variable "name_prefix" {
  description = "Prefix for all IAM resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.name_prefix))
    error_message = "Name prefix must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Lambda Role Configuration
# -----------------------------------------------------------------------------

variable "create_lambda_role" {
  description = "Whether to create Lambda execution role"
  type        = bool
  default     = true
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing permissions for Lambda"
  type        = bool
  default     = false
}

variable "enable_lambda_vpc_access" {
  description = "Enable VPC access permissions for Lambda"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# ECS Task Role Configuration
# -----------------------------------------------------------------------------

variable "create_ecs_task_role" {
  description = "Whether to create ECS task and execution roles"
  type        = bool
  default     = true
}

variable "ecs_secret_arns" {
  description = "List of Secrets Manager secret ARNs for ECS task access"
  type        = list(string)
  default     = []
}

variable "ecs_ssm_parameter_arns" {
  description = "List of SSM Parameter Store ARNs for ECS task access"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# EC2 SSM Role Configuration
# -----------------------------------------------------------------------------

variable "create_ec2_ssm_role" {
  description = "Whether to create EC2 instance profile with SSM access"
  type        = bool
  default     = true
}

variable "enable_ec2_cloudwatch" {
  description = "Enable CloudWatch Agent permissions for EC2"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Cross-Account Role Configuration
# -----------------------------------------------------------------------------

variable "create_cross_account_role" {
  description = "Whether to create cross-account assume role"
  type        = bool
  default     = false
}

variable "trusted_account_ids" {
  description = "List of AWS account IDs allowed to assume the cross-account role"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.trusted_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "All account IDs must be 12-digit numbers."
  }
}

variable "require_external_id" {
  description = "Require external ID for cross-account role assumption"
  type        = bool
  default     = true
}

variable "external_id" {
  description = "External ID for cross-account role assumption (required if require_external_id is true)"
  type        = string
  default     = null
  sensitive   = true
}

variable "cross_account_purpose" {
  description = "Description of the cross-account role purpose"
  type        = string
  default     = "cross-account access"
}

variable "cross_account_policy_json" {
  description = "JSON policy document for cross-account role permissions"
  type        = string
  default     = null
}

variable "cross_account_max_session_duration" {
  description = "Maximum session duration in seconds for cross-account role (1-12 hours)"
  type        = number
  default     = 3600

  validation {
    condition     = var.cross_account_max_session_duration >= 3600 && var.cross_account_max_session_duration <= 43200
    error_message = "Max session duration must be between 3600 (1 hour) and 43200 (12 hours)."
  }
}
