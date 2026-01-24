# Outputs for Task 1: S3 Bucket with Lifecycle Policies

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.centralized_storage.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.centralized_storage.arn
}

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.centralized_storage.id
}

output "bucket_region" {
  description = "AWS region of the S3 bucket"
  value       = aws_s3_bucket.centralized_storage.region
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.centralized_storage.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.centralized_storage.bucket_regional_domain_name
}

output "backups_prefix" {
  description = "Prefix for backup data"
  value       = "backups/"
}

output "profile_pictures_prefix" {
  description = "Prefix for profile pictures"
  value       = "profile-pictures/"
}

output "logging_bucket_name" {
  description = "Name of the logging bucket (if enabled)"
  value       = var.enable_logging ? aws_s3_bucket.logging_bucket[0].bucket : null
}

output "lifecycle_policy_summary" {
  description = "Summary of lifecycle policies applied"
  value = {
    backups = {
      "0-30_days"    = "S3 Standard"
      "31-90_days"   = "S3 Standard-IA"
      "91-180_days"  = "S3 Glacier Flexible Retrieval"
      "181-365_days" = "S3 Glacier Deep Archive"
      "after_1_year" = "Deleted"
    }
    profile_pictures = {
      storage_class = "S3 One Zone-IA (set at upload time)"
      expiration    = "None"
    }
  }
}
