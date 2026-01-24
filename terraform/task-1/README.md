# Task 1: S3 Bucket with Lifecycle Policies

<!-- markdownlint-disable MD022 MD032 MD034 MD060 -->

## Overview

This Terraform configuration creates an S3 bucket with cost-optimized lifecycle policies for two different use cases:
1. **Backup data** - Automatically transitions through storage classes and expires after 1 year
2. **Profile pictures** - Stored in One Zone-IA for cost-effective frequent access

## Architecture

### Bucket Structure
- Single S3 bucket with two prefixes:
  - `backups/` - Backup data with tiered lifecycle transitions
  - `profile-pictures/` - User profile images

### Backup Data Lifecycle (`backups/` prefix)

| Age | Storage Class | Access Pattern | Restoration SLA |
|-----|---------------|----------------|-----------------|
| 0-30 days | S3 Standard | Frequently accessed | Milliseconds |
| 31-90 days | S3 Standard-IA | 1-2 times/month | Milliseconds |
| 91-180 days | Glacier Flexible Retrieval | Rarely accessed | Up to 2 hours |
| 181-365 days | Glacier Deep Archive | Compliance storage | Up to 24 hours |
| After 365 days | **Deleted** | N/A | N/A |

### Profile Pictures Storage (`profile-pictures/` prefix)

- **Storage Class**: S3 One Zone-IA (set at upload time)
- **Rationale**: Non-critical, frequently accessed data. Users can re-upload if lost.
- **Cost Savings**: ~20% cheaper than Standard-IA while maintaining millisecond access
- **No expiration**: Pictures remain as long as user account is active

**Important:** Terraform cannot enforce a default storage class for a prefix. To achieve One Zone-IA immediately, the application (or CLI/SDK) must set the object storage class on upload (e.g., `x-amz-storage-class: ONEZONE_IA`).

## Security Configuration

- ✅ Server-Side Encryption (SSE-S3 with AES-256)
- ✅ All public access blocked
- ✅ Versioning disabled (cost optimization)
- ✅ Incomplete multipart upload cleanup (7 days)
- ⚙️ Optional S3 access logging

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS account with S3 permissions

## Usage

### 1. Initialize Terraform

```bash
cd terraform/task-1
terraform init
```

### 2. Create Variables File

Copy the example and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region     = "us-east-1"
bucket_name    = "your-unique-bucket-name"  # Must be globally unique
environment    = "prod"
enable_logging = false
```

### 3. Plan the Deployment

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 5. View Outputs

```bash
terraform output
```

## Outputs

| Output | Description |
|--------|-------------|
| `bucket_name` | Name of the S3 bucket |
| `bucket_arn` | ARN of the S3 bucket |
| `bucket_domain_name` | Domain name for API access |
| `backups_prefix` | Prefix for backup data (`backups/`) |
| `profile_pictures_prefix` | Prefix for profile pictures (`profile-pictures/`) |
| `lifecycle_policy_summary` | Summary of all lifecycle policies |

## Cost Optimization Features

1. **Automatic Tiering** - Data automatically moves to cheaper storage classes as it ages
2. **Automatic Deletion** - Backup data is purged after 1 year
3. **One Zone-IA for Non-Critical Data** - Profile pictures use lower-cost storage
4. **Single Bucket Architecture** - Reduced management overhead
5. **Multipart Upload Cleanup** - Prevents charges for incomplete uploads
6. **Optional Logging** - Enable only if needed for compliance

## Example Usage

### Uploading Backup Data

```bash
# Upload to backups/ prefix
aws s3 cp backup-file.tar.gz s3://your-bucket-name/backups/2026-01-22/backup-file.tar.gz
```

### Uploading Profile Pictures

```bash
# Upload to profile-pictures/ prefix with One Zone-IA storage class
aws s3 cp user-123-avatar.jpg s3://your-bucket-name/profile-pictures/user-123/avatar.jpg \
  --storage-class ONEZONE_IA
```

**Important:** Profile pictures should be uploaded with the `ONEZONE_IA` storage class to achieve cost optimization immediately. Lifecycle transitions require a minimum of 30 days, which doesn't meet the requirement for immediate frequent access at a lower cost.

### API Access with Consistent URL

The bucket provides a consistent destination URL for API calls:

```python
import boto3

s3_client = boto3.client("s3")
bucket_name = "your-bucket-name"

# Upload backup data under backups/
s3_client.upload_file(
  "local-backup.tar.gz",
  bucket_name,
  "backups/2026-01-22/local-backup.tar.gz",
)

# Upload profile picture under profile-pictures/ with One Zone-IA
s3_client.upload_file(
  "avatar.jpg",
  bucket_name,
  "profile-pictures/user-123/avatar.jpg",
  ExtraArgs={"StorageClass": "ONEZONE_IA"},
)

# Retrieve profile picture
s3_client.download_file(
  bucket_name,
  "profile-pictures/user-123/avatar.jpg",
  "downloaded-avatar.jpg",
)
```

## Cleanup

To destroy all resources created by this configuration:

```bash
terraform destroy
```

⚠️ **Warning**: This will permanently delete the bucket and all its contents. Make sure you have backups of any important data.

## Cost Estimation

Approximate monthly costs for typical usage:

| Component | Volume | Cost |
|-----------|--------|------|
| S3 Standard (0-30 days) | 100 GB | $2.30 |
| S3 Standard-IA (31-90 days) | 100 GB | $1.25 |
| Glacier Flexible (91-180 days) | 100 GB | $0.36 |
| Glacier Deep Archive (181-365 days) | 100 GB | $0.10 |
| One Zone-IA (Profile Pictures) | 10 GB | $0.10 |
| Data Transfer (to internet) | 50 GB | $4.50 |
| **Estimated Total** | | **~$8.60/month** |

*Costs vary by region and usage patterns. Use the [AWS Pricing Calculator](https://calculator.aws/) for accurate estimates.*

## Additional Notes

- **Bucket Naming**: S3 bucket names must be globally unique across all AWS accounts
- **Region Consideration**: Choose a region close to your primary users for lower latency
- **IAM Policies**: You'll need to create separate IAM policies for application access
- **Monitoring**: Consider enabling CloudWatch metrics for S3 to track storage and access patterns
- **Compliance**: Lifecycle policies automatically handle data retention requirements

## Support

For issues or questions:
1. Check AWS S3 documentation: https://docs.aws.amazon.com/s3/
2. Review Terraform AWS provider docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
3. Submit an issue to the project repository
