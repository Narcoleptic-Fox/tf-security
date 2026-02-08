# Required tags
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "development", "stg", "staging", "prod", "production", "test"], lower(var.environment))
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "project" {
  description = "Project or product name"
  type        = string
}

variable "owner" {
  description = "Team or individual responsible for the resource"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
}

# Optional tags
variable "application" {
  description = "Application name (if different from project)"
  type        = string
  default     = null
}

variable "team" {
  description = "Team name"
  type        = string
  default     = null
}

variable "repository" {
  description = "Source code repository URL"
  type        = string
  default     = null
}

variable "compliance" {
  description = "Compliance framework (e.g., SOC2, HIPAA, PCI-DSS)"
  type        = string
  default     = null
}

variable "extra_tags" {
  description = "Additional custom tags to merge"
  type        = map(string)
  default     = {}
}
