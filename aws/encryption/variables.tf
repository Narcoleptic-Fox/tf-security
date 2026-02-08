variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# KMS Key Configuration
# -----------------------------------------------------------------------------

variable "key_description" {
  description = "Description for the KMS key"
  type        = string
  default     = null
}

variable "deletion_window_in_days" {
  description = "Duration in days before the key is deleted after destruction (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic key rotation"
  type        = bool
  default     = true
}

variable "multi_region" {
  description = "Create a multi-region KMS key"
  type        = bool
  default     = false
}

variable "alias_suffix" {
  description = "Optional suffix for the KMS alias"
  type        = string
  default     = ""
}

variable "additional_aliases" {
  description = "Additional KMS key aliases to create"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Key Policy - Principals
# -----------------------------------------------------------------------------

variable "key_admin_arns" {
  description = "ARNs of IAM principals that can administer the key"
  type        = list(string)
  default     = []
}

variable "key_user_arns" {
  description = "ARNs of IAM principals that can use the key for encryption/decryption"
  type        = list(string)
  default     = []
}

variable "cross_account_arns" {
  description = "ARNs of cross-account principals allowed to use the key"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Key Policy - Service Access
# -----------------------------------------------------------------------------

variable "enable_cloudwatch_logs" {
  description = "Allow CloudWatch Logs service to use the key"
  type        = bool
  default     = true
}

variable "enable_s3" {
  description = "Allow S3 service to use the key"
  type        = bool
  default     = true
}

variable "enable_sns" {
  description = "Allow SNS service to use the key"
  type        = bool
  default     = false
}

variable "enable_sqs" {
  description = "Allow SQS service to use the key"
  type        = bool
  default     = false
}

variable "enable_lambda" {
  description = "Allow Lambda service to use the key"
  type        = bool
  default     = false
}

variable "enable_secrets_manager" {
  description = "Allow Secrets Manager service to use the key"
  type        = bool
  default     = true
}

variable "enable_ssm" {
  description = "Allow SSM service to use the key"
  type        = bool
  default     = true
}

variable "enable_rds" {
  description = "Allow RDS service to use the key"
  type        = bool
  default     = false
}

variable "enable_ebs" {
  description = "Allow EC2 (EBS) service to use the key"
  type        = bool
  default     = false
}

variable "additional_service_principals" {
  description = "Additional AWS service principals allowed to use the key"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# S3 Secure Bucket Configuration
# -----------------------------------------------------------------------------

variable "create_secure_bucket" {
  description = "Create a secure S3 bucket with encryption defaults"
  type        = bool
  default     = false
}

variable "bucket_name" {
  description = "Name for the secure S3 bucket (defaults to account-id-name-prefix-secure)"
  type        = string
  default     = null
}

variable "enable_bucket_key" {
  description = "Enable S3 Bucket Key for cost reduction"
  type        = bool
  default     = true
}

variable "enable_bucket_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "access_log_bucket" {
  description = "Target bucket for access logging"
  type        = string
  default     = null
}

variable "enable_lifecycle_rules" {
  description = "Enable lifecycle rules for cost optimization"
  type        = bool
  default     = true
}

variable "transition_to_ia_days" {
  description = "Days before transitioning objects to STANDARD_IA"
  type        = number
  default     = 30
}

variable "transition_to_glacier_days" {
  description = "Days before transitioning objects to GLACIER (null to disable)"
  type        = number
  default     = 90
}

variable "noncurrent_transition_days" {
  description = "Days before transitioning noncurrent versions to STANDARD_IA"
  type        = number
  default     = 30
}

variable "noncurrent_expiration_days" {
  description = "Days before expiring noncurrent versions"
  type        = number
  default     = 365
}
