# Task 4: EC2 Cost Optimization with Terraform

This Terraform module implements a cost-optimized EC2 infrastructure for Task 4 of the Udacity AWS Solutions Architect Associate project. The module provisions a right-sized EC2 instance with optimized storage, security groups, and proper cost allocation tagging.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Cost Optimization Strategy](#cost-optimization-strategy)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Variables](#variables)
- [Outputs](#outputs)
- [Cost Analysis](#cost-analysis)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)

---

## Overview

### Scenario
A software development company has a QA EC2 instance (`qa-instance-1`) with high monthly costs. Performance monitoring revealed:

- **CPU utilization**: 70% peak, 40% off-peak
- **Memory usage**: 60% peak, 20% off-peak
- **Disk I/O**: 75 IOPS peak, 50 IOPS off-peak

This Terraform module implements cost optimization recommendations by:
1. Right-sizing to a T3 burstable instance
2. Using gp3 EBS volumes instead of over-provisioned storage
3. Applying cost allocation tags for tracking
4. Providing flexible security group configuration

---

## Architecture

The module provisions:

- **EC2 Instance**: T3 family instance (default: `t3.medium`) with burstable CPU credits
- **Security Group**: VPC security group with configurable ingress/egress rules
- **EBS Volume**: gp3 root volume with 3,000 baseline IOPS
- **AMI Selection**: Latest Amazon Linux 2023 AMI (or custom AMI)
- **Cost Allocation Tags**: Environment, Team, Project tags for cost tracking

---

## Cost Optimization Strategy

### Why T3 Instances?

T3 instances are **burstable performance** instances ideal for variable workloads like QA environments:

| Feature | Fixed Instance (e.g., m5.large) | T3 Instance (e.g., t3.medium) |
|---------|----------------------------------|-------------------------------|
| CPU Credits | N/A | Earns credits during idle time |
| Peak Performance | Consistent | Burst to 100% when needed |
| Off-Peak Cost | Full price 24/7 | Lower baseline cost |
| **Monthly Cost** | **~$70** | **~$30** |
| **Savings** | — | **~$40/month (57%)** |

**Key Benefits:**
- CPU credits accumulate during 40% off-peak usage
- Burst to handle 70% peak usage without throttling
- Significantly cheaper than fixed-performance instances

### Why gp3 Volumes?

| Storage Type | IOPS Provisioned | Monthly Cost (100GB) | Suitable For |
|--------------|------------------|----------------------|--------------|
| **io1/io2** (Provisioned IOPS) | 75 IOPS | ~$70-100 | High-performance databases |
| **gp2** (General Purpose SSD) | 300 IOPS (baseline) | ~$10 | General workloads |
| **gp3** (Latest Gen SSD) | 3,000 IOPS (baseline) | ~$8 | Cost-optimized workloads |

**For this QA workload:**
- Requires only 75 IOPS peak
- gp3 provides 3,000 IOPS baseline (40x the requirement!)
- **Savings**: $2-92/month depending on current storage type

### Total Expected Savings

| Component | Before (Over-Provisioned) | After (Optimized) | Monthly Savings |
|-----------|---------------------------|-------------------|-----------------|
| Instance Type | m5.xlarge (~$140) | t3.medium (~$30) | ~$110 |
| Storage | io1 100GB (~$70) | gp3 20GB (~$2) | ~$68 |
| **Total** | **~$210/month** | **~$32/month** | **~$178/month (85%)** |

*Note: Actual savings depend on your current configuration. Use AWS Pricing Calculator for precise estimates.*

---

## Prerequisites

Before using this module, ensure you have:

1. **AWS Account** with appropriate permissions:
   - EC2 instance creation/management
   - VPC and Security Group management
   - IAM permissions (if using instance profiles)

2. **Terraform** installed (>= 1.0):
   ```bash
   terraform version
   ```

3. **AWS CLI** configured (optional but recommended):
   ```bash
   aws configure
   ```

4. **Existing AWS Resources**:
   - VPC ID where the instance will be launched
   - Subnet ID within that VPC
   - SSH key pair created in AWS (for instance access)

5. **Network Access**:
   - Know your IP address/CIDR for SSH access restrictions

---

## Usage

### Step 1: Clone or Navigate to the Directory

```bash
cd terraform/task-4/
```

### Step 2: Create `terraform.tfvars`

Copy the example file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your configuration:

```hcl
aws_region = "us-east-1"

# REQUIRED: Update with your VPC/Subnet IDs
vpc_id    = "vpc-0123456789abcdef0"
subnet_id = "subnet-0123456789abcdef0"

# REQUIRED: Update with your key pair name
key_pair_name = "my-ec2-keypair"

# RECOMMENDED: Restrict SSH access to your IP
ssh_cidr_blocks = ["203.0.113.0/32"]  # Replace with your IP

# Cost allocation tags
environment = "QA"
team        = "Engineering"
project     = "qa-instance-1"

# Instance configuration
instance_type = "t3.medium"
instance_name = "qa-instance-1"

# Storage configuration
root_volume_type = "gp3"
root_volume_size = 20
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This downloads the AWS provider and initializes the working directory.

### Step 4: Review the Plan

```bash
terraform plan
```

Review the resources that will be created:
- EC2 instance (t3.medium)
- Security group with configured rules
- EBS gp3 root volume

### Step 5: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to create the resources.

### Step 6: Verify the Deployment

After successful apply, Terraform will output:

```
Outputs:

instance_id = "i-0123456789abcdef0"
private_ip = "10.0.1.50"
public_ip = "54.123.45.67"
ssh_connection_command = "ssh -i /path/to/my-ec2-keypair.pem ec2-user@54.123.45.67"
security_group_id = "sg-0123456789abcdef0"
```

### Step 7: Connect to the Instance

```bash
ssh -i /path/to/your-key.pem ec2-user@<public_ip>
```

### Step 8: Verify Cost Optimization

Once connected, verify the instance configuration:

```bash
# Check instance type
curl http://169.254.169.254/latest/meta-data/instance-type

# Check CPU credits (T3 instances)
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUCreditBalance \
  --dimensions Name=InstanceId,Value=<instance-id> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Average

# Check EBS volume type
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
aws ec2 describe-volumes --volume-ids <volume-id>
```

---

## Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `vpc_id` | string | VPC ID where the instance will be launched |
| `subnet_id` | string | Subnet ID within the VPC |
| `key_pair_name` | string | Name of the SSH key pair |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `us-east-1` | AWS region for resources |
| `instance_type` | string | `t3.medium` | EC2 instance type (T3 family recommended) |
| `instance_name` | string | `qa-instance-1` | Name tag for the instance |
| `environment` | string | `QA` | Environment tag for cost allocation |
| `team` | string | `Engineering` | Team tag for cost allocation |
| `project` | string | `qa-instance-1` | Project tag for cost allocation |
| `root_volume_type` | string | `gp3` | EBS volume type |
| `root_volume_size` | number | `20` | Root volume size in GB |
| `enable_ebs_encryption` | bool | `true` | Enable EBS encryption |
| `ssh_cidr_blocks` | list(string) | `[]` | CIDR blocks for SSH access |
| `custom_ami_id` | string | `""` | Custom AMI ID (uses latest AL2023 if empty) |
| `iam_instance_profile_name` | string | `""` | IAM instance profile for AWS service access |

See [variables.tf](variables.tf) for complete list.

---

## Outputs

| Output | Description |
|--------|-------------|
| `instance_id` | EC2 instance ID |
| `instance_state` | Current instance state |
| `private_ip` | Private IP address |
| `public_ip` | Public IP address (if assigned) |
| `availability_zone` | Availability zone of the instance |
| `security_group_id` | Security group ID |
| `root_volume_id` | Root EBS volume ID |
| `root_volume_type` | Root volume type (should be gp3) |
| `ssh_connection_command` | SSH command to connect |

---

## Cost Analysis

### Monthly Cost Breakdown (t3.medium in us-east-1)

| Resource | Configuration | Monthly Cost |
|----------|---------------|--------------|
| EC2 Instance | t3.medium (2 vCPU, 4GB RAM) | ~$30.37 |
| EBS Volume | gp3 20GB | ~$1.60 |
| Data Transfer | 1GB outbound (free tier) | ~$0.00 |
| **Total** | — | **~$32/month** |

### Comparison with Over-Provisioned Configuration

| Scenario | Instance Type | Storage | Monthly Cost |
|----------|---------------|---------|--------------|
| **Before (Over-provisioned)** | m5.xlarge | io1 100GB (1000 IOPS) | ~$210 |
| **After (Right-sized)** | t3.medium | gp3 20GB | ~$32 |
| **Savings** | — | — | **~$178/month (85%)** |

### Annual Savings

```
Annual Savings = $178/month × 12 months = $2,136/year
```

---

## Security Considerations

### Security Best Practices

1. **Restrict SSH Access**:
   ```hcl
   ssh_cidr_blocks = ["YOUR_IP/32"]  # Replace with your IP
   ```

2. **Enable EBS Encryption**:
   ```hcl
   enable_ebs_encryption = true
   ```

3. **Use IAM Instance Profile** (instead of storing credentials):
   ```hcl
   iam_instance_profile_name = "SSMInstanceProfile"
   ```

4. **Use AWS Systems Manager Session Manager** (no SSH key needed):
   - Attach IAM role with `AmazonSSMManagedInstanceCore` policy
   - Connect via AWS Console or CLI without opening port 22

5. **Regular Security Updates**:
   ```bash
   sudo yum update -y
   ```

---

## Troubleshooting

### Issue: "InvalidKeyPair.NotFound"

**Solution**: Ensure the key pair exists in your AWS account and region:

```bash
aws ec2 describe-key-pairs --key-names your-key-pair-name
```

Create a key pair if needed:

```bash
aws ec2 create-key-pair --key-name your-key-pair-name --query 'KeyMaterial' --output text > your-key-pair-name.pem
chmod 400 your-key-pair-name.pem
```

### Issue: "UnauthorizedOperation"

**Solution**: Ensure your AWS credentials have EC2 permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### Issue: "InvalidSubnetID.NotFound"

**Solution**: Verify your VPC and Subnet IDs:

```bash
aws ec2 describe-vpcs
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxxx"
```

### Issue: Instance state remains "pending"

**Solution**: Check EC2 instance status checks in AWS Console:

```bash
aws ec2 describe-instance-status --instance-ids i-xxxxxx
```

---

## Cleanup

To destroy all resources created by this module:

```bash
terraform destroy
```

Type `yes` when prompted.

**Note**: This will permanently delete the instance and all associated data on the root volume.

---

## References

- [AWS EC2 T3 Instances](https://aws.amazon.com/ec2/instance-types/t3/)
- [AWS EBS Volume Types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html)
- [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## Support

For issues or questions:
1. Review the [Troubleshooting](#troubleshooting) section
2. Check Terraform and AWS provider documentation
3. Consult AWS Support or community forums
