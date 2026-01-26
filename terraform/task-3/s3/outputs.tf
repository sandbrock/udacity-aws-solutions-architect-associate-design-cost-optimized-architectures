output "demo_production_bucket_name" {
  description = "Name of the Production demo S3 bucket"
  value       = aws_s3_bucket.demo_production.id
}

output "demo_development_bucket_name" {
  description = "Name of the Development demo S3 bucket"
  value       = aws_s3_bucket.demo_development.id
}
