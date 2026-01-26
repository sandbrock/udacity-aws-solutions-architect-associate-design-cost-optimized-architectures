terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get current account ID
data "aws_caller_identity" "current" {}

# Demo Resources for Cost Allocation Tag Illustration
# S3 Bucket for Production Environment
resource "aws_s3_bucket" "demo_production" {
  bucket = "${lower(var.budget_name)}-demo-production-${data.aws_caller_identity.current.account_id}"

  tags = {
    Environment = "Production"
    Team        = "Engineering"
    Project     = "CostDemo"
    ManagedBy   = "Terraform"
  }
}

# S3 Bucket for Development Environment
resource "aws_s3_bucket" "demo_development" {
  bucket = "${lower(var.budget_name)}-demo-development-${data.aws_caller_identity.current.account_id}"

  tags = {
    Environment = "Development"
    Team        = "Analytics"
    Project     = "CostDemo"
    ManagedBy   = "Terraform"
  }
}
