# AWS Region
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# Budget Configuration
variable "budget_name" {
  description = "Name of the AWS Budget"
  type        = string
  default     = "AdSpark-Monthly-Budget"

  validation {
    condition     = length(var.budget_name) > 0 && length(var.budget_name) <= 100
    error_message = "Budget name must be between 1 and 100 characters."
  }
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 1000

  validation {
    condition     = var.budget_limit > 0
    error_message = "Budget limit must be a positive number."
  }
}

# Email Notification Configuration
variable "alert_emails_50pct" {
  description = "List of email addresses to receive alerts when budget reaches 50% threshold"
  type        = list(string)
  default     = ["finance-alerts@adspark.com"]

  validation {
    condition     = length(var.alert_emails_50pct) > 0
    error_message = "At least one email address must be provided for 50% alerts."
  }
}

variable "alert_emails_80pct" {
  description = "List of email addresses to receive alerts when budget reaches 80% threshold"
  type        = list(string)
  default     = ["finance-alerts@adspark.com", "ops-team@adspark.com"]

  validation {
    condition     = length(var.alert_emails_80pct) > 0
    error_message = "At least one email address must be provided for 80% alerts."
  }
}

# Common Tags
variable "tags" {
  description = "Common tags to apply to all resources for cost allocation and organization"
  type        = map(string)
  default = {
    Environment = "Production"
    Team        = "Finance"
    Project     = "CostControl"
    ManagedBy   = "Terraform"
  }
}
