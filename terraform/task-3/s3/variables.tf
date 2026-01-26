# AWS Region
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# Budget Name (used for bucket naming)
variable "budget_name" {
  description = "Name prefix for demo S3 buckets"
  type        = string
  default     = "AdSpark-Monthly-Budget"
}
