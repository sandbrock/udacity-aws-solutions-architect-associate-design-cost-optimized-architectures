variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for static website hosting (must be globally unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be lowercase alphanumeric with hyphens, 3-63 characters long."
  }
}

variable "environment" {
  description = "Environment name for resource tagging (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "price_class" {
  description = "CloudFront distribution price class (PriceClass_100, PriceClass_200, or PriceClass_All)"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Price class must be one of: PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "domain_name" {
  description = "Custom domain name for the website (optional). If specified, acm_certificate_arn must also be provided"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for custom domain (optional, required if domain_name is set). Must be in us-east-1 region"
  type        = string
  default     = ""

  validation {
    condition     = var.domain_name == "" || var.acm_certificate_arn != ""
    error_message = "If domain_name is provided, acm_certificate_arn must also be provided."
  }
}

variable "create_dns_records" {
  description = "Whether to create Route 53 DNS records for the custom domain"
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for DNS records (required if create_dns_records is true)"
  type        = string
  default     = ""

  validation {
    condition     = !var.create_dns_records || var.hosted_zone_id != ""
    error_message = "If create_dns_records is true, hosted_zone_id must be provided."
  }
}

variable "enable_logging" {
  description = "Whether to enable CloudFront access logging"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "S3 bucket name for CloudFront access logs (required if enable_logging is true). Must have proper logging permissions"
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_logging || var.logging_bucket != ""
    error_message = "If enable_logging is true, logging_bucket must be provided."
  }
}

variable "logging_prefix" {
  description = "Prefix for CloudFront log files in the logging bucket"
  type        = string
  default     = "cloudfront-logs/"
}
