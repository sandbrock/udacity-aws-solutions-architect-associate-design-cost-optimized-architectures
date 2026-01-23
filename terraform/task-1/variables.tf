# Variables for Task 1: S3 Bucket with Lifecycle Policies

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for centralized storage"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be lowercase alphanumeric with hyphens, and cannot start or end with a hyphen."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "enable_logging" {
  description = "Enable S3 access logging to a separate bucket"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain S3 access logs"
  type        = number
  default     = 90
}
