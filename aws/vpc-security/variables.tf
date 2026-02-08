variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (for NACL rules)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Security Group Configuration
# -----------------------------------------------------------------------------

variable "create_web_security_group" {
  description = "Create security group for web tier"
  type        = bool
  default     = true
}

variable "create_app_security_group" {
  description = "Create security group for application tier"
  type        = bool
  default     = true
}

variable "create_db_security_group" {
  description = "Create security group for database tier"
  type        = bool
  default     = true
}

variable "web_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access web tier"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "web_ingress_ipv6_cidr_blocks" {
  description = "IPv6 CIDR blocks allowed to access web tier"
  type        = list(string)
  default     = ["::/0"]
}

variable "allow_http" {
  description = "Allow HTTP (port 80) traffic (for HTTPS redirect)"
  type        = bool
  default     = true
}

variable "app_port" {
  description = "Port for application tier (e.g., 8080, 3000)"
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port > 0 && var.app_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

variable "db_port" {
  description = "Port for database tier"
  type        = number
  default     = 5432

  validation {
    condition     = var.db_port > 0 && var.db_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

# -----------------------------------------------------------------------------
# NACL Configuration
# -----------------------------------------------------------------------------

variable "create_public_nacl" {
  description = "Create Network ACL for public subnets"
  type        = bool
  default     = true
}

variable "create_private_nacl" {
  description = "Create Network ACL for private subnets"
  type        = bool
  default     = true
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for NACL association"
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for NACL association"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# VPC Flow Logs Configuration
# -----------------------------------------------------------------------------

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_destination" {
  description = "Destination type for flow logs (cloud-watch-logs or s3)"
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log_destination)
    error_message = "Flow log destination must be cloud-watch-logs or s3."
  }
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to log (ACCEPT, REJECT, or ALL)"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "Traffic type must be ACCEPT, REJECT, or ALL."
  }
}

variable "flow_log_retention_days" {
  description = "CloudWatch Logs retention in days (0 = never expire)"
  type        = number
  default     = 30

  validation {
    condition = contains([
      0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.flow_log_retention_days)
    error_message = "Retention days must be a valid CloudWatch Logs retention value."
  }
}

variable "flow_log_kms_key_arn" {
  description = "KMS key ARN for encrypting flow logs"
  type        = string
  default     = null
}

variable "flow_log_s3_bucket_arn" {
  description = "S3 bucket ARN for flow logs (required if destination is s3)"
  type        = string
  default     = null
}

variable "flow_log_aggregation_interval" {
  description = "Aggregation interval in seconds (60 or 600)"
  type        = number
  default     = 60

  validation {
    condition     = contains([60, 600], var.flow_log_aggregation_interval)
    error_message = "Aggregation interval must be 60 or 600 seconds."
  }
}

variable "flow_log_file_format" {
  description = "File format for S3 flow logs (plain-text or parquet)"
  type        = string
  default     = "parquet"

  validation {
    condition     = contains(["plain-text", "parquet"], var.flow_log_file_format)
    error_message = "File format must be plain-text or parquet."
  }
}

variable "flow_log_per_hour_partition" {
  description = "Enable per-hour partitioning for S3 flow logs"
  type        = bool
  default     = true
}
