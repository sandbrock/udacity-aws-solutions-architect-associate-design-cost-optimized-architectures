# Task 2: Cost-Optimized Static Website with S3 and CloudFront

## Overview

This Terraform module provisions a cost-optimized static website hosting solution for **Nexlify Solutions** using Amazon S3 and CloudFront CDN. This architecture demonstrates AWS best practices for hosting static websites at minimal cost—typically just a few dollars per month—compared to EC2-based alternatives that can cost $50+ per month.

### Business Scenario

Nexlify Solutions needs to host their static marketing website with the following requirements:
- **Cost optimization**: Minimize monthly hosting expenses
- **Performance**: Fast content delivery globally
- **Security**: HTTPS support and secure S3 access
- **Simplicity**: Low operational overhead

### Solution Architecture

```
┌─────────────┐
│  End Users  │ (HTTPS requests)
└──────┬──────┘
       │
       ▼
┌──────────────────────────┐
│   CloudFront CDN         │ ← Global edge locations
│   (Content Delivery)     │ ← HTTPS termination
└──────────┬───────────────┘ ← 24-hour cache (cost optimization)
           │
           │ Origin Access Control (OAC)
           │
           ▼
    ┌──────────────────┐
    │   S3 Bucket      │ ← Private bucket
    │ (Static Website) │ ← Encrypted (SSE-S3)
    │   - index.html   │
    │   - error.html   │
    │   - assets/      │
    └──────────────────┘
```

**Key Components:**
1. **S3 Bucket**: Stores website files with encryption and blocked public access
2. **CloudFront Distribution**: Global CDN with HTTPS, caching, and compression
3. **Origin Access Control (OAC)**: Secure access from CloudFront to private S3 bucket
4. **S3 Bucket Policy**: Grants CloudFront read-only access via OAC

---

## Cost Analysis

### Monthly Cost Breakdown

**Traditional EC2 Hosting:**
- EC2 t3.small instance: ~$15-17/month (24/7 operation)
- Elastic IP: ~$3.65/month
- EBS storage: ~$8/month (80GB)
- Data transfer: ~$9/month (100GB)
- **Total: ~$35-50+/month**

**S3 + CloudFront (This Solution):**
- S3 storage (1GB): ~$0.023/month
- S3 GET requests (1M): ~$0.40/month
- CloudFront data transfer (100GB): ~$8.50/month
- CloudFront requests (1M): ~$1.00/month
- **Total: ~$1-10/month** (depends on traffic)

### Cost Optimization Strategies

1. **CloudFront Caching**: 24-hour default TTL reduces S3 requests by ~95%
2. **Price Class 100**: North America + Europe only (cheaper than global)
3. **Compression**: Automatic gzip/brotli reduces data transfer costs
4. **No Compute Costs**: No EC2 instances = no idle compute charges
5. **S3 Lifecycle Policies**: Archive old logs to Glacier (if logging enabled)

**Cost Savings: ~$25-40/month (70-80% reduction)**

---

## Prerequisites

Before using this Terraform module:

1. **Terraform**: Version 1.0 or higher
   ```bash
   terraform version
   ```

2. **AWS Account**: Active AWS account with appropriate credentials

3. **AWS CLI**: Configured with access credentials
   ```bash
   aws configure
   # Or use environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
   ```

4. **Required IAM Permissions**:
   - `s3:CreateBucket`, `s3:PutBucketPolicy`, `s3:PutEncryptionConfiguration`
   - `cloudfront:CreateDistribution`, `cloudfront:CreateOriginAccessControl`
   - `route53:ChangeResourceRecordSets` (if using custom domain with Route 53)

5. **Optional Prerequisites** (for custom domain):
   - Registered domain name
   - ACM SSL/TLS certificate in `us-east-1` region
   - Route 53 hosted zone (if using automatic DNS configuration)

---

## Usage

### Step 1: Initialize Terraform

Navigate to the `terraform/task-2/` directory and initialize Terraform:

```bash
cd terraform/task-2
terraform init
```

This downloads the required AWS provider plugin.

### Step 2: Create Configuration File

Copy the example configuration and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region  = "us-east-1"
bucket_name = "your-unique-bucket-name"  # Must be globally unique
environment = "prod"
```

**Important:** The `bucket_name` must be globally unique across all AWS accounts.

### Step 3: Plan the Deployment

Preview the infrastructure changes:

```bash
terraform plan
```

Review the output to ensure:
- S3 bucket will be created with encryption
- CloudFront distribution will be configured
- Origin Access Control will secure S3 access
- No unexpected resources are being created

### Step 4: Apply the Configuration

Provision the infrastructure:

```bash
terraform apply
```

Type `yes` when prompted. Deployment takes ~10-15 minutes (CloudFront distribution creation is slow).

### Step 5: Upload Website Content

After Terraform finishes, upload your website files to S3:

```bash
# Get the bucket name from Terraform output
BUCKET_NAME=$(terraform output -raw bucket_name)

# Upload index.html
aws s3 cp index.html s3://$BUCKET_NAME/

# Upload error.html
aws s3 cp error.html s3://$BUCKET_NAME/

# Upload entire assets directory
aws s3 cp assets/ s3://$BUCKET_NAME/assets/ --recursive

# Set proper content types for better caching
aws s3 cp styles.css s3://$BUCKET_NAME/ --content-type "text/css"
aws s3 cp script.js s3://$BUCKET_NAME/ --content-type "application/javascript"
```

**Sample index.html** (minimal example):
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Nexlify Solutions</title>
</head>
<body>
    <h1>Welcome to Nexlify Solutions</h1>
    <p>Cost-optimized static website hosting on AWS!</p>
</body>
</html>
```

**Sample error.html**:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Page Not Found</title>
</head>
<body>
    <h1>404 - Page Not Found</h1>
    <p>The page you're looking for doesn't exist.</p>
</body>
</html>
```

### Step 6: Access Your Website

Get the CloudFront URL from Terraform output:

```bash
terraform output website_url
```

Open the URL in your browser. The website should load via HTTPS.

**Note:** CloudFront distributions take 15-20 minutes to fully deploy. If you get an error initially, wait a few minutes and try again.

---

## Configuration

### Required Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `bucket_name` | string | S3 bucket name (must be globally unique) | `"nexlify-website-prod"` |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `"us-east-1"` | AWS region for S3 bucket |
| `environment` | string | `"prod"` | Environment tag (dev, staging, prod) |
| `price_class` | string | `"PriceClass_100"` | CloudFront price class (cost optimization) |
| `domain_name` | string | `""` | Custom domain name (optional) |
| `acm_certificate_arn` | string | `""` | ACM certificate ARN (required if domain_name is set) |
| `create_dns_records` | bool | `false` | Create Route 53 DNS records |
| `hosted_zone_id` | string | `""` | Route 53 hosted zone ID (required if create_dns_records = true) |
| `enable_logging` | bool | `false` | Enable CloudFront access logging |
| `logging_bucket` | string | `""` | S3 bucket for logs (required if enable_logging = true) |
| `logging_prefix` | string | `"cloudfront-logs/"` | Prefix for log files |

### CloudFront Price Classes

- **PriceClass_100** (Recommended): North America + Europe (~cheapest)
- **PriceClass_200**: Adds Asia, South America, Australia
- **PriceClass_All**: All CloudFront edge locations worldwide

Choose `PriceClass_100` for cost optimization if your users are primarily in North America/Europe.

---

## Outputs

After `terraform apply`, the following outputs are available:

```bash
terraform output
```

| Output | Description |
|--------|-------------|
| `bucket_name` | S3 bucket name |
| `bucket_arn` | S3 bucket ARN |
| `bucket_regional_domain_name` | S3 bucket regional domain |
| `cloudfront_distribution_id` | CloudFront distribution ID (for invalidations) |
| `cloudfront_domain_name` | CloudFront URL (e.g., `d123456abcdef.cloudfront.net`) |
| `cloudfront_arn` | CloudFront distribution ARN |
| `website_url` | Full HTTPS URL to access website |

### Invalidating CloudFront Cache

When you update website files in S3, CloudFront may serve cached versions. To force immediate updates:

```bash
# Get distribution ID
DIST_ID=$(terraform output -raw cloudfront_distribution_id)

# Invalidate all files
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"

# Invalidate specific file
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/index.html"
```

**Note:** First 1,000 invalidation paths per month are free; additional paths cost $0.005 each.

---

## Custom Domain Setup (Optional)

To use a custom domain like `www.nexlify.com`:

### Step 1: Create ACM Certificate

Create an SSL/TLS certificate in `us-east-1` (required for CloudFront):

```bash
aws acm request-certificate \
  --domain-name nexlify.com \
  --subject-alternative-names www.nexlify.com \
  --validation-method DNS \
  --region us-east-1
```

Validate the certificate using DNS validation (add CNAME records to your DNS).

### Step 2: Configure Terraform Variables

Update `terraform.tfvars`:

```hcl
domain_name         = "nexlify.com"
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcd-1234-..."
```

### Step 3: Optional Route 53 DNS

If your domain is hosted in Route 53, enable automatic DNS record creation:

```hcl
create_dns_records = true
hosted_zone_id     = "Z1234567890ABC"
```

This creates A records for `nexlify.com` and `www.nexlify.com` pointing to CloudFront.

If you use external DNS (GoDaddy, Namecheap, etc.), manually create CNAME records:
- `nexlify.com` → CloudFront domain name
- `www.nexlify.com` → CloudFront domain name

### Step 4: Apply Configuration

```bash
terraform apply
```

Wait for CloudFront to deploy (~15-20 minutes), then access your website via the custom domain.

---

## Security Features

### 1. Private S3 Bucket
- All public access blocked
- No public bucket policies
- Direct S3 URL access returns 403 Forbidden

### 2. Origin Access Control (OAC)
- CloudFront authenticates to S3 using AWS signatures
- S3 bucket policy grants access only to CloudFront
- Replaces legacy Origin Access Identity (OAI)

### 3. Encryption
- S3 server-side encryption (SSE-S3) enabled by default
- HTTPS enforced via CloudFront (HTTP redirects to HTTPS)
- TLS 1.2+ for all connections

### 4. Secure Headers
- CloudFront automatically adds security headers
- Compression reduces bandwidth (gzip/brotli)

### Testing Security

```bash
# Test S3 direct access (should return 403 Forbidden)
BUCKET_URL=$(terraform output -raw bucket_regional_domain_name)
curl -I https://$BUCKET_URL/index.html
# Expected: HTTP 403 Forbidden

# Test CloudFront access (should return 200 OK)
CLOUDFRONT_URL=$(terraform output -raw website_url)
curl -I $CLOUDFRONT_URL
# Expected: HTTP 200 OK
```

---

## Troubleshooting

### Issue: "Bucket name already exists"

**Error:** `BucketAlreadyExists: The requested bucket name is not available`

**Solution:** S3 bucket names must be globally unique. Change `bucket_name` in `terraform.tfvars` to something unique (e.g., add a random suffix).

### Issue: CloudFront returns "AccessDenied"

**Symptoms:** CloudFront URL returns XML error with `AccessDenied`

**Solutions:**
1. Verify S3 bucket policy is applied: `terraform state show aws_s3_bucket_policy.website`
2. Check files were uploaded to S3: `aws s3 ls s3://your-bucket-name`
3. Wait 5-10 minutes for CloudFront distribution to fully deploy

### Issue: Custom domain not working

**Symptoms:** Custom domain shows CloudFront default certificate error

**Solutions:**
1. Verify ACM certificate is in `us-east-1` region
2. Ensure certificate includes both apex and www subdomain
3. Check DNS records propagation: `dig your-domain.com`
4. Wait up to 48 hours for DNS propagation

### Issue: Changes not reflecting on website

**Symptom:** Updated S3 files but website shows old content

**Solution:** CloudFront caches content for 24 hours. Either:
1. Wait for cache expiration
2. Create CloudFront invalidation (see "Invalidating CloudFront Cache" above)
3. Use versioned filenames (e.g., `styles.v2.css`)

### Issue: Terraform state locked

**Error:** `Error: Error acquiring the state lock`

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

---

## Cleanup

To destroy all resources and avoid ongoing charges:

```bash
# Remove all files from S3 bucket first (Terraform can't delete non-empty buckets)
BUCKET_NAME=$(terraform output -raw bucket_name)
aws s3 rm s3://$BUCKET_NAME --recursive

# Destroy infrastructure
terraform destroy
```

Type `yes` when prompted. This removes:
- CloudFront distribution (~10-15 minutes)
- S3 bucket and policies
- Route 53 records (if created)
- Origin Access Control

**Cost after cleanup:** $0 (no resources remain)

---

## Additional Resources

- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront with S3 Origin](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistS3AndCustomOrigins.html)
- [CloudFront Origin Access Control](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
- [S3 Pricing](https://aws.amazon.com/s3/pricing/)

---

## License

This Terraform module is provided as-is for educational purposes as part of the Udacity AWS Solutions Architect Associate course.

---

## Architecture Diagram

```
Internet
   │
   │ HTTPS (Port 443)
   ▼
┌────────────────────────────────────────┐
│     CloudFront Edge Locations          │
│  (50+ locations worldwide)             │
│                                        │
│  ┌──────────────────────────────┐     │
│  │  Cache Layer (24hr TTL)      │     │
│  │  - HTML, CSS, JS, Images     │     │
│  │  - Gzip/Brotli compression   │     │
│  └──────────────────────────────┘     │
└────────┬───────────────────────────────┘
         │ OAC (Origin Access Control)
         │ Signed requests (SigV4)
         │
         ▼
┌────────────────────────────────────────┐
│         S3 Bucket (Private)            │
│  ┌──────────────────────────────┐     │
│  │  Website Files:              │     │
│  │  - /index.html               │     │
│  │  - /error.html               │     │
│  │  - /assets/logo.png          │     │
│  │  - /styles.css               │     │
│  └──────────────────────────────┘     │
│                                        │
│  Encryption: SSE-S3 (AES-256)         │
│  Public Access: BLOCKED                │
└────────────────────────────────────────┘
```

---

**Last Updated:** 2026-01-22  
**Terraform Version:** >= 1.0  
**AWS Provider Version:** ~> 5.0
