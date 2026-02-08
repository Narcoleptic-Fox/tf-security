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
# GuardDuty Detector Configuration
# -----------------------------------------------------------------------------

variable "finding_publishing_frequency" {
  description = "Frequency of findings publishing (FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS)"
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "Finding publishing frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

# -----------------------------------------------------------------------------
# Protection Features
# -----------------------------------------------------------------------------

variable "enable_s3_protection" {
  description = "Enable S3 protection (monitors S3 data access events)"
  type        = bool
  default     = true
}

variable "enable_kubernetes_protection" {
  description = "Enable Kubernetes audit logs monitoring"
  type        = bool
  default     = true
}

variable "enable_malware_protection" {
  description = "Enable malware protection for EC2 (scans EBS volumes)"
  type        = bool
  default     = true
}

variable "enable_runtime_monitoring" {
  description = "Enable runtime monitoring for containers"
  type        = bool
  default     = false
}

variable "enable_eks_runtime_monitoring" {
  description = "Enable EKS runtime monitoring (requires enable_runtime_monitoring)"
  type        = bool
  default     = false
}

variable "enable_ecs_runtime_monitoring" {
  description = "Enable ECS Fargate runtime monitoring (requires enable_runtime_monitoring)"
  type        = bool
  default     = false
}

variable "enable_lambda_protection" {
  description = "Enable Lambda network activity monitoring"
  type        = bool
  default     = false
}

variable "enable_rds_protection" {
  description = "Enable RDS login activity monitoring"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# SNS Notifications
# -----------------------------------------------------------------------------

variable "create_sns_topic" {
  description = "Create SNS topic for GuardDuty findings"
  type        = bool
  default     = true
}

variable "sns_kms_key_arn" {
  description = "KMS key ARN for SNS topic encryption"
  type        = string
  default     = null
}

variable "notification_email_addresses" {
  description = "Email addresses to subscribe to findings notifications"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# EventBridge Integration
# -----------------------------------------------------------------------------

variable "enable_eventbridge_notifications" {
  description = "Enable EventBridge rules for findings notifications"
  type        = bool
  default     = true
}

variable "min_severity_for_notification" {
  description = "Minimum severity level for notifications (1-8.9, null for all)"
  type        = number
  default     = 4

  validation {
    condition     = var.min_severity_for_notification == null || (var.min_severity_for_notification >= 1 && var.min_severity_for_notification <= 8.9)
    error_message = "Minimum severity must be between 1 and 8.9."
  }
}

variable "enable_high_severity_alert" {
  description = "Create separate rule for high severity findings (7+)"
  type        = bool
  default     = true
}

variable "lambda_function_arn" {
  description = "Lambda function ARN to invoke for findings processing"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Suppression Filters
# -----------------------------------------------------------------------------

variable "suppression_filters" {
  description = "Map of suppression filters for known false positives"
  type = map(object({
    rank = number
    criteria = list(object({
      field                 = string
      equals                = optional(list(string))
      not_equals            = optional(list(string))
      greater_than          = optional(string)
      greater_than_or_equal = optional(string)
      less_than             = optional(string)
      less_than_or_equal    = optional(string)
    }))
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# IP Lists
# -----------------------------------------------------------------------------

variable "trusted_ip_list_location" {
  description = "S3 URI for trusted IP list (s3://bucket/prefix/file.txt)"
  type        = string
  default     = null
}

variable "trusted_ip_list_format" {
  description = "Format of trusted IP list (TXT, STIX, OTX_CSV, ALIEN_VAULT, PROOF_POINT, FIRE_EYE)"
  type        = string
  default     = "TXT"

  validation {
    condition     = contains(["TXT", "STIX", "OTX_CSV", "ALIEN_VAULT", "PROOF_POINT", "FIRE_EYE"], var.trusted_ip_list_format)
    error_message = "IP list format must be TXT, STIX, OTX_CSV, ALIEN_VAULT, PROOF_POINT, or FIRE_EYE."
  }
}

variable "threat_intel_set_location" {
  description = "S3 URI for custom threat intelligence set"
  type        = string
  default     = null
}

variable "threat_intel_set_format" {
  description = "Format of threat intel set (TXT, STIX, OTX_CSV, ALIEN_VAULT, PROOF_POINT, FIRE_EYE)"
  type        = string
  default     = "TXT"

  validation {
    condition     = contains(["TXT", "STIX", "OTX_CSV", "ALIEN_VAULT", "PROOF_POINT", "FIRE_EYE"], var.threat_intel_set_format)
    error_message = "Threat intel format must be TXT, STIX, OTX_CSV, ALIEN_VAULT, PROOF_POINT, or FIRE_EYE."
  }
}
