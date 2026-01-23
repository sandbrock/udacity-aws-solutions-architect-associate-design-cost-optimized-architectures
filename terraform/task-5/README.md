# Task 5: NAT Gateway vs NAT Instance Cost Comparison

## Overview

This Terraform infrastructure implements a cost comparison between **AWS NAT Gateway** and **NAT Instance** solutions for DevMetrics, a cloud-based SaaS analytics platform. The infrastructure provisions a production-ready VPC with public and private subnets across two Availability Zones, demonstrating both NAT solutions for providing internet access to microservices in private subnets.

**Business Scenario:** DevMetrics hosts microservices in private subnets for security while requiring outbound internet access for API calls, software updates, and external service integrations. The challenge is balancing cost efficiency with operational requirements for high availability, performance, and ease of management.

This implementation allows you to:
- Deploy and test both NAT solutions in parallel
- Compare actual AWS costs using Cost Explorer
- Validate the 92% cost savings claimed for NAT Instance over NAT Gateway
- Understand the architectural trade-offs of each solution

**Related Documentation:** See [Task 5 in the main README](../../README.md#task-5) for the business scenario and detailed cost analysis.

---

## Architecture

### Multi-AZ VPC Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              VPC: 10.0.0.0/16                             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌─────────────────────────────┬────────────────────────────────┐        │
│  │  Availability Zone 1 (us-east-1a)  │  Availability Zone 2 (us-east-1b)  │
│  ├─────────────────────────────┼────────────────────────────────┤        │
│  │                             │                                │        │
│  │ ┌─────────────────────────┐ │ ┌──────────────────────────┐   │        │
│  │ │   Public Subnet         │ │ │   Public Subnet          │   │        │
│  │ │   10.0.1.0/24           │ │ │   10.0.2.0/24            │   │        │
│  │ │                         │ │ │                          │   │        │
│  │ │  ┌─────────────────┐    │ │ │  ┌─────────────────┐   │   │        │
│  │ │  │  NAT Gateway    │    │ │ │  │  NAT Gateway    │   │   │        │
│  │ │  │  (Elastic IP)   │    │ │ │  │  (Elastic IP)   │   │   │        │
│  │ │  └────────┬────────┘    │ │ │  └────────┬────────┘   │   │        │
│  │ │           │              │ │ │           │            │   │        │
│  │ │  ┌────────┴────────┐    │ │ │  ┌────────┴────────┐   │   │        │
│  │ │  │  NAT Instance   │    │ │ │  │  NAT Instance   │   │   │        │
│  │ │  │  (t3.nano)      │    │ │ │  │  (t3.nano)      │   │   │        │
│  │ │  └─────────────────┘    │ │ │  └─────────────────┘   │   │        │
│  │ └─────────┬───────────────┘ │ └──────────┬─────────────┘   │        │
│  │           │                 │            │                 │        │
│  │           │                 │            │                 │        │
│  │ ┌─────────┴───────────────┐ │ ┌──────────┴─────────────┐   │        │
│  │ │   Private Subnet        │ │ │   Private Subnet       │   │        │
│  │ │   10.0.101.0/24         │ │ │   10.0.102.0/24        │   │        │
│  │ │                         │ │ │                        │   │        │
│  │ │  ┌─────────────────┐    │ │ │  ┌─────────────────┐   │   │        │
│  │ │  │  Microservices  │    │ │ │  │  Microservices  │   │   │        │
│  │ │  │  (No Public IP) │    │ │ │  │  (No Public IP) │   │   │        │
│  │ │  └─────────────────┘    │ │ │  └─────────────────┘   │   │        │
│  │ └─────────────────────────┘ │ └──────────────────────────┘   │        │
│  └─────────────────────────────┴────────────────────────────────┘        │
│                                  │                                        │
│                          ┌───────┴───────┐                               │
│                          │ Internet      │                               │
│                          │ Gateway (IGW) │                               │
│                          └───────────────┘                               │
└──────────────────────────────────────────────────────────────────────────┘
```

**Key Components:**
- **VPC:** 10.0.0.0/16 with DNS hostnames and support enabled
- **Internet Gateway:** Provides internet access for public subnets
- **Public Subnets:** Two subnets (10.0.1.0/24, 10.0.2.0/24) with public IP auto-assignment
- **Private Subnets:** Two subnets (10.0.101.0/24, 10.0.102.0/24) for microservices
- **NAT Gateway:** AWS-managed NAT service with automatic high availability within each AZ
- **NAT Instance:** Self-managed EC2 instances (t3.nano) with iptables-based NAT

---

## Cost Comparison

### Monthly Cost Breakdown (1,000 GB Data Transfer)

| Component | NAT Gateway | NAT Instance (t3.nano) | Difference |
|-----------|-------------|------------------------|------------|
| **Compute/Service Charge** | $65.70 (2 × $32.85/month) | $6.77 (2 × $3.38/month, 730 hrs) | **-$58.93** |
| **Data Processing** | $45.00 (1,000 GB × $0.045/GB) | $0 (no data processing charge) | **-$45.00** |
| **Storage (EBS)** | N/A (included) | $2.10 (2 × 8 GB gp3 × $0.08/GB) | **+$2.10** |
| **Elastic IP** | Included with NAT Gateway | $0 (attached to running instance) | $0 |
| **Data Transfer Out** | Varies by destination | Varies by destination | $0 (same) |
| **Total Monthly Cost** | **$110.70** | **$8.87** | **-$101.83 (92% savings)** |

*Costs based on US East (N. Virginia) region pricing as of 2024. Actual costs may vary based on region and usage patterns.*

### Cost Scaling Analysis

| Data Transfer | NAT Gateway | NAT Instance | Savings | Savings % |
|---------------|-------------|--------------|---------|-----------|
| 500 GB/month | $88.20 | $8.87 | $79.33 | 90% |
| 1,000 GB/month | $110.70 | $8.87 | $101.83 | 92% |
| 2,000 GB/month | $155.70 | $8.87 | $146.83 | 94% |
| 5,000 GB/month | $290.70 | $8.87 | $281.83 | 97% |

**Key Insight:** Cost savings increase with data transfer volume due to NAT Gateway's $0.045/GB processing fee.

---

## Feature Comparison

| Feature | NAT Gateway | NAT Instance (t3.nano) | Winner |
|---------|-------------|------------------------|--------|
| **High Availability** | Automatic within AZ, multi-AZ requires multiple NGWs | Manual (requires Auto Scaling, health checks, route failover) | NAT Gateway |
| **Bandwidth** | Up to 100 Gbps (automatic scaling) | Limited by instance type (~5 Gbps for t3.nano burst) | NAT Gateway |
| **Performance** | Consistent, AWS-managed | Variable, depends on instance health and CPU credits | NAT Gateway |
| **Maintenance** | Zero (fully managed) | OS patching, security updates, monitoring required | NAT Gateway |
| **Setup Complexity** | Simple (1 resource) | Complex (EC2, security groups, IAM roles, user data, monitoring) | NAT Gateway |
| **Monthly Cost** | $110.70 (1 TB transfer) | $8.87 (1 TB transfer) | NAT Instance |
| **Cost Predictability** | Variable (data processing charges) | Fixed (instance hours only) | NAT Instance |
| **Security Hardening** | Not required (managed) | Required (OS, iptables, SSM access) | NAT Gateway |
| **Monitoring** | Built-in CloudWatch metrics | Manual CloudWatch alarm setup | NAT Gateway |
| **Best For** | Production, high-traffic, mission-critical | Development, QA, low-traffic, cost-sensitive | Depends |

### Recommendation by Workload

- **Use NAT Gateway if:**
  - You need guaranteed high availability without manual intervention
  - Your workload has unpredictable traffic spikes
  - You want zero operational overhead
  - Bandwidth requirements exceed 1 Gbps consistently

- **Use NAT Instance if:**
  - Cost is the primary concern (92% savings)
  - Traffic is predictable and low to moderate (< 1 Gbps)
  - You have DevOps capacity for maintenance and monitoring
  - The environment is non-production (dev, QA, staging)

**DevMetrics Decision (from Task 5):** NAT Instance was recommended due to predictable traffic patterns, 92% cost savings, and acceptable maintenance overhead for the QA environment.

---

## Prerequisites

Before deploying this infrastructure, ensure you have:

1. **OpenTofu** >= 1.5.0 installed ([download](https://opentofu.org/docs/intro/install/))
2. **AWS CLI** configured with valid credentials ([setup guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html))
3. **AWS Permissions** for the following services:
   - VPC (create/modify VPCs, subnets, route tables, internet gateways)
   - EC2 (launch instances, manage security groups, Elastic IPs, NAT Gateways)
   - IAM (create roles, instance profiles, policy attachments)
   - CloudWatch (create alarms)
4. **AWS Account** with sufficient service limits:
   - VPCs: 5 per region (default)
   - Elastic IPs: 5 per region (default, request increase if needed)
   - NAT Gateways: 5 per AZ (default)

---

## Usage Instructions

### 1. Initialize OpenTofu

```bash
cd terraform/task-5
tofu init
```

This downloads the AWS provider and initializes the working directory.

### 2. Configure Variables

Copy the example configuration file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to select your NAT solution:

**Option A: Deploy NAT Gateway (Managed, Higher Cost)**
```hcl
enable_nat_gateway  = true
enable_nat_instance = false
```

**Option B: Deploy NAT Instance (Self-Managed, Lower Cost)**
```hcl
enable_nat_gateway  = false
enable_nat_instance = true
nat_instance_type   = "t3.nano"
```

**Option C: Deploy Both Solutions for Comparison**
```hcl
enable_nat_gateway  = true
enable_nat_instance = true
nat_instance_type   = "t3.nano"
```

### 3. Review Planned Changes

```bash
tofu plan
```

Review the resources that will be created. Verify:
- 1 VPC
- 2 public subnets (one per AZ)
- 2 private subnets (one per AZ)
- 1 Internet Gateway
- NAT Gateway resources (if `enable_nat_gateway = true`)
- NAT Instance resources (if `enable_nat_instance = true`)

### 4. Deploy Infrastructure

```bash
tofu apply
```

Type `yes` when prompted to confirm deployment. This will take 3-5 minutes for NAT Gateway, or 2-3 minutes for NAT Instance.

### 5. Retrieve Outputs

```bash
tofu output
```

Example output:
```
vpc_id = "vpc-0a1b2c3d4e5f67890"
public_subnet_ids = [
  "subnet-0a1b2c3d",
  "subnet-4e5f6g7h"
]
private_subnet_ids = [
  "subnet-8i9j0k1l",
  "subnet-2m3n4o5p"
]
nat_gateway_ids = [
  "nat-0a1b2c3d4e5f67890",
  "nat-1a2b3c4d5e6f78901"
]
```

---

## Testing Internet Connectivity

### Test 1: Launch EC2 Instance in Private Subnet

1. **Launch a test instance** in one of the private subnets:
```bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --subnet-id $(tofu output -raw private_subnet_ids | jq -r '.[0]') \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nat-test-instance}]'
```

2. **Connect to the instance** using AWS Systems Manager Session Manager (no SSH key required):
```bash
aws ssm start-session --target <instance-id>
```

*Alternative:* Use a bastion host in the public subnet if SSM is not configured.

### Test 2: Verify Outbound Internet Access

From the private subnet instance, test internet connectivity:

```bash
# Test DNS resolution
nslookup google.com

# Test HTTP connectivity
curl -I https://www.google.com

# Test HTTPS connectivity
curl -I https://api.github.com

# Check public IP (should show NAT Gateway or NAT Instance IP)
curl ifconfig.me
```

**Expected Results:**
- DNS queries resolve successfully
- HTTP/HTTPS requests return `200 OK` status
- Public IP matches the Elastic IP of the NAT Gateway or NAT Instance

### Test 3: Verify NAT Instance Configuration (if using NAT Instance)

1. **Connect to the NAT Instance** (from within the VPC or via SSM):
```bash
aws ssm start-session --target <nat-instance-id>
```

2. **Check IP forwarding** (should return `1`):
```bash
sysctl net.ipv4.ip_forward
```

3. **Check iptables NAT rules**:
```bash
sudo iptables -t nat -L -n -v
```

You should see a MASQUERADE rule in the POSTROUTING chain.

4. **Review user data execution log**:
```bash
sudo cat /var/log/user-data.log
```

Look for "NAT Instance configuration completed successfully".

---

## Switching Between NAT Solutions

To switch from NAT Gateway to NAT Instance (or vice versa):

1. **Edit `terraform.tfvars`**:
```hcl
# Switch from NAT Gateway to NAT Instance
enable_nat_gateway  = false  # Changed from true
enable_nat_instance = true   # Changed from false
```

2. **Run `tofu plan`** to review changes:
```bash
tofu plan
```

You'll see:
- NAT Gateway resources marked for destruction (if switching away from NGW)
- NAT Instance resources marked for creation (if switching to NAT Instance)
- Private route table routes updated to point to new NAT solution

3. **Apply changes**:
```bash
tofu apply
```

**Note:** During the transition, private subnet instances will temporarily lose internet connectivity (typically 30-60 seconds).

---

## Cost Tracking with AWS Cost Explorer

After running both NAT solutions for 24-48 hours, compare actual costs:

### 1. Activate Cost Allocation Tags

1. Navigate to **AWS Billing Console** → **Cost Allocation Tags**
2. Activate these tags:
   - `Solution` (will show "NAT-Gateway" or "NAT-Instance")
   - `Project` (will show "Task5")
   - `Environment`
3. Wait 24 hours for tags to appear in Cost Explorer

### 2. View NAT Gateway Costs

1. Open **AWS Cost Explorer**
2. Set time range to last 7 or 30 days
3. Group by: **Tag** → `Solution`
4. Filter: `Solution` = `NAT-Gateway`
5. Review costs for:
   - EC2-Other (NAT Gateway service charge)
   - Data Transfer

### 3. View NAT Instance Costs

1. In Cost Explorer, filter: `Solution` = `NAT-Instance`
2. Review costs for:
   - EC2-Instances (t3.nano compute)
   - EBS (storage)
   - Data Transfer

### 4. Compare Total Costs

Create a custom report:
- Dimension: Tag → `Solution`
- Time period: Monthly
- Granularity: Daily or Monthly

**Expected Results:** NAT Instance should show ~92% lower costs than NAT Gateway for comparable data transfer volumes.

---

## Monitoring and Alarms

### NAT Gateway Monitoring

AWS automatically provides CloudWatch metrics for NAT Gateways:
- **ActiveConnectionCount**: Number of concurrent active TCP connections
- **BytesInFromDestination**: Bytes received from destination
- **BytesInFromSource**: Bytes received from source
- **BytesOutToDestination**: Bytes sent to destination
- **BytesOutToSource**: Bytes sent to source
- **ErrorPortAllocation**: Number of times NAT Gateway couldn't allocate a source port
- **PacketsDropCount**: Number of packets dropped by NAT Gateway

View in: **CloudWatch Console** → **Metrics** → **NATGateway**

### NAT Instance Monitoring

This Terraform configuration creates CloudWatch alarms for NAT Instance health:

**StatusCheckFailed Alarm:**
- **Metric:** `StatusCheckFailed` (combines system and instance checks)
- **Threshold:** >= 1 failed check
- **Evaluation:** 2 consecutive periods (2 minutes)
- **Action:** Alarm transitions to ALARM state (SNS notification if configured)

**View Alarms:**
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix task5-nat-comparison-nat-instance
```

**Manual Monitoring:**
```bash
# Check NAT Instance CPU usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=<nat-instance-id> \
  --start-time 2024-01-20T00:00:00Z \
  --end-time 2024-01-21T00:00:00Z \
  --period 3600 \
  --statistics Average

# Check network throughput
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name NetworkOut \
  --dimensions Name=InstanceId,Value=<nat-instance-id> \
  --start-time 2024-01-20T00:00:00Z \
  --end-time 2024-01-21T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

---

## Cleanup

### Destroy All Resources

```bash
tofu destroy
```

Type `yes` when prompted. This will delete all resources created by Terraform.

**Important:** Verify destruction in the AWS Console:
1. **EC2 Dashboard** → Check for terminated instances, released Elastic IPs, deleted NAT Gateways
2. **VPC Dashboard** → Verify VPC, subnets, route tables, and IGW are deleted
3. **CloudWatch Console** → Check that alarms are removed

### Partial Cleanup (Keep VPC, Remove NAT Solutions)

If you want to keep the VPC but remove NAT costs:

1. Edit `terraform.tfvars`:
```hcl
enable_nat_gateway  = false
enable_nat_instance = false
```

2. Apply changes:
```bash
tofu apply
```

This removes NAT Gateways, NAT Instances, and associated resources while preserving the VPC and subnets.

---

## Troubleshooting

### Issue: Private subnet instances can't reach the internet

**Possible Causes:**
1. **NAT Gateway/Instance not running**
   - Check: `tofu output` shows NAT resource IDs
   - Verify in AWS Console that resources are in "available" state

2. **Route table misconfiguration**
   - Check: `aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<vpc-id>"`
   - Verify 0.0.0.0/0 routes point to NAT Gateway or NAT Instance

3. **NAT Instance source/destination check enabled**
   - Check: `aws ec2 describe-instances --instance-ids <nat-instance-id> --query 'Reservations[].Instances[].SourceDestCheck'`
   - Should return `false` (disabled)

4. **NAT Instance user data failed**
   - SSH to NAT Instance and check: `sudo cat /var/log/user-data.log`
   - Verify IP forwarding: `sysctl net.ipv4.ip_forward` (should be 1)
   - Check iptables: `sudo iptables -t nat -L -n -v`

5. **Security group blocking traffic**
   - NAT Instance SG should allow all traffic from private subnet CIDRs
   - Check: `aws ec2 describe-security-groups --group-ids <nat-sg-id>`

### Issue: NAT Instance alarm constantly triggering

**Possible Causes:**
1. **Instance undersized for traffic**
   - Increase instance type: Change `nat_instance_type = "t3.small"` in `terraform.tfvars`
   - Run `tofu apply`

2. **CPU credits exhausted** (T3 instances)
   - Check: CloudWatch → CPUCreditBalance metric
   - Solution: Switch to T3 Unlimited or use M5/C5 instances

### Issue: High NAT Gateway costs

**Possible Causes:**
1. **Excessive data processing charges**
   - Check: Cost Explorer → Filter by "Data Transfer" category
   - Solution: Reduce outbound data transfer or switch to NAT Instance

2. **Redundant NAT Gateways**
   - If you don't need multi-AZ HA, reduce to 1 NAT Gateway
   - Update `availability_zones = ["us-east-1a"]` in `terraform.tfvars`

---

## File Structure

```
terraform/task-5/
├── main.tf                      # VPC, subnets, IGW, NAT Gateway resources
├── nat-instance.tf              # NAT Instance, security groups, IAM roles, CloudWatch alarms
├── variables.tf                 # Input variable declarations
├── outputs.tf                   # Output value declarations
├── user-data.sh                 # NAT Instance initialization script (IP forwarding, iptables)
├── terraform.tfvars.example     # Example configuration file
├── README.md                    # This file
└── .gitignore                   # Excludes terraform.tfvars and state files
```

---

## Security Considerations

### NAT Gateway
- **No SSH access required** (fully managed by AWS)
- **Automatic security updates** applied by AWS
- **DDoS protection** via AWS Shield Standard

### NAT Instance
- **Disable SSH from internet:** Security group only allows private subnet traffic
- **Enable SSM Session Manager:** For secure access without SSH keys
- **Regular OS patching:** Use AWS Systems Manager Patch Manager
- **Minimize attack surface:** Only install required packages
- **Enable VPC Flow Logs:** Monitor traffic patterns for anomalies
- **Use IMDSv2:** Protect against SSRF attacks (enabled by default on AL2023)

**Recommendation:** For production environments requiring maximum security, use NAT Gateway unless cost constraints are critical.

---

## References

- [AWS NAT Gateway Pricing](https://aws.amazon.com/vpc/pricing/)
- [AWS EC2 Pricing (t3.nano)](https://aws.amazon.com/ec2/pricing/on-demand/)
- [NAT Instances Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html)
- [NAT Gateway Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [High Availability for NAT Instances](https://aws.amazon.com/articles/high-availability-for-amazon-vpc-nat-instances-an-example/)
- [OpenTofu AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## Support

For issues or questions:
1. Review [Troubleshooting](#troubleshooting) section
2. Check OpenTofu logs: `TF_LOG=DEBUG tofu apply`
3. Consult AWS documentation for specific service errors
4. Open an issue in the project repository

---

## License

This project is licensed under the MIT License. See the main repository for details.
