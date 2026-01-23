# Task 1: S3 Bucket with Lifecycle Policies for Backups and Profile Pictures
# 
# This configuration creates an S3 bucket with:
# - Separate prefixes for backups/ and profile-pictures/
# - Lifecycle policies for backup data tiering and expiration
# - Cost-optimized storage for profile pictures

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

# S3 Bucket for centralized storage
resource "aws_s3_bucket" "centralized_storage" {
  bucket = var.bucket_name

  tags = {
    Name        = "Centralized Storage Bucket"
    Environment = var.environment
    Purpose     = "Backups and Profile Pictures"
    ManagedBy   = "Terraform"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "centralized_storage" {
  bucket = aws_s3_bucket.centralized_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "centralized_storage" {
  bucket = aws_s3_bucket.centralized_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for backup data (backups/ prefix)
# Transitions through storage classes based on access patterns
resource "aws_s3_bucket_lifecycle_configuration" "centralized_storage" {
  bucket = aws_s3_bucket.centralized_storage.id

  # Backup data lifecycle rule
  rule {
    id     = "backup-data-lifecycle"
    status = "Enabled"

    filter {
      prefix = "backups/"
    }

    # 0-30 days: S3 Standard (default, no transition needed)

    # 31-90 days: Move to Standard-IA
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # 91-180 days: Move to Glacier Flexible Retrieval
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # 181-365 days: Move to Glacier Deep Archive
    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }

    # After 1 year: Delete
    expiration {
      days = 365
    }

    # Clean up incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Profile pictures: Clean up incomplete uploads
  # Note: Profile pictures should be uploaded directly with ONEZONE_IA storage class
  # using the x-amz-storage-class header. S3 lifecycle transitions require a minimum
  # of 30 days, but profile pictures need to be in One Zone-IA immediately for
  # cost optimization while maintaining frequent access performance.
  rule {
    id     = "profile-pictures-cleanup"
    status = "Enabled"

    filter {
      prefix = "profile-pictures/"
    }

    # Clean up incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Versioning is disabled by default for cost optimization
# Backups are point-in-time snapshots; profile pictures are user-replaceable
resource "aws_s3_bucket_versioning" "centralized_storage" {
  bucket = aws_s3_bucket.centralized_storage.id

  versioning_configuration {
    status = "Disabled"
  }
}

# Optional: Enable bucket logging for audit purposes
resource "aws_s3_bucket_logging" "centralized_storage" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.centralized_storage.id

  target_bucket = aws_s3_bucket.logging_bucket[0].id
  target_prefix = "s3-access-logs/"
}

# Optional: Logging bucket (only created if logging is enabled)
resource "aws_s3_bucket" "logging_bucket" {
  count = var.enable_logging ? 1 : 0

  bucket = "${var.bucket_name}-logs"

  tags = {
    Name        = "S3 Access Logs Bucket"
    Environment = var.environment
    Purpose     = "Access Logging"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "logging_bucket" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.logging_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable lifecycle policy on logging bucket to expire old logs
resource "aws_s3_bucket_lifecycle_configuration" "logging_bucket" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.logging_bucket[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    # Apply to all objects in the bucket
    filter {}

    expiration {
      days = var.log_retention_days
    }
  }
}
