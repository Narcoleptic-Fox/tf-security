variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting logs"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# CloudTrail Configuration
# -----------------------------------------------------------------------------

variable "create_cloudtrail" {
  description = "Create CloudTrail trail"
  type        = bool
  default     = true
}

variable "create_cloudtrail_bucket" {
  description = "Create S3 bucket for CloudTrail logs"
  type        = bool
  default     = true
}

variable "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket (required if create_cloudtrail_bucket is false)"
  type        = string
  default     = null
}

variable "cloudtrail_s3_key_prefix" {
  description = "S3 key prefix for CloudTrail logs"
  type        = string
  default     = null
}

variable "include_global_service_events" {
  description = "Include global service events (IAM, STS, etc.)"
  type        = bool
  default     = true
}

variable "is_multi_region_trail" {
  description = "Enable multi-region trail"
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "Enable log file integrity validation"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Send CloudTrail logs to CloudWatch"
  type        = bool
  default     = true
}

variable "cloudtrail_log_retention_days" {
  description = "CloudWatch Logs retention for CloudTrail (days)"
  type        = number
  default     = 90

  validation {
    condition = contains([
      0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.cloudtrail_log_retention_days)
    error_message = "Retention days must be a valid CloudWatch Logs retention value."
  }
}

# -----------------------------------------------------------------------------
# CloudTrail Data Events
# -----------------------------------------------------------------------------

variable "enable_data_events" {
  description = "Enable data event logging (S3, Lambda)"
  type        = bool
  default     = false
}

variable "data_event_s3_buckets" {
  description = "S3 bucket ARNs for data event logging (use 'arn:aws:s3' for all buckets)"
  type        = list(string)
  default     = []
}

variable "data_event_lambda_functions" {
  description = "Lambda function ARNs for data event logging (use 'arn:aws:lambda' for all functions)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# CloudTrail S3 Lifecycle
# -----------------------------------------------------------------------------

variable "cloudtrail_transition_to_ia_days" {
  description = "Days before transitioning CloudTrail logs to STANDARD_IA"
  type        = number
  default     = 30
}

variable "cloudtrail_transition_to_glacier_days" {
  description = "Days before transitioning CloudTrail logs to GLACIER"
  type        = number
  default     = 90
}

variable "cloudtrail_expiration_days" {
  description = "Days before expiring CloudTrail logs"
  type        = number
  default     = 365
}

# -----------------------------------------------------------------------------
# Application Log Groups
# -----------------------------------------------------------------------------

variable "application_log_groups" {
  description = "Map of application log groups to create"
  type = map(object({
    name           = string
    retention_days = optional(number)
    kms_key_arn    = optional(string)
  }))
  default = {}
}

variable "default_log_retention_days" {
  description = "Default retention for application log groups"
  type        = number
  default     = 30

  validation {
    condition = contains([
      0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.default_log_retention_days)
    error_message = "Retention days must be a valid CloudWatch Logs retention value."
  }
}

# -----------------------------------------------------------------------------
# Security Monitoring
# -----------------------------------------------------------------------------

variable "enable_security_metric_filters" {
  description = "Create metric filters for security events"
  type        = bool
  default     = true
}

variable "enable_security_alarms" {
  description = "Create CloudWatch alarms for security events"
  type        = bool
  default     = true
}

variable "metric_namespace" {
  description = "CloudWatch metric namespace for security metrics"
  type        = string
  default     = "SecurityMetrics"
}

variable "alarm_sns_topic_arns" {
  description = "SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}
