variable "project" {
  description = "Project or product name (alphanumeric, will be lowercased)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.project))
    error_message = "Project must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "development", "stg", "staging", "prod", "production", "test", "tst"], lower(var.environment))
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "region" {
  description = "Cloud region (AWS or Azure format)"
  type        = string
}

variable "suffix" {
  description = "Optional suffix to append (e.g., for uniqueness)"
  type        = string
  default     = ""
}
