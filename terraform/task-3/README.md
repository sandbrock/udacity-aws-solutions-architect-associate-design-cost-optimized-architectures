# Task 3: AWS Budget with Cost Alerts

## Solution Overview

This Terraform configuration implements AWS cost control infrastructure for the AdSpark digital marketing startup scenario. The solution addresses the CFO's concerns about runaway AWS costs by providing:

1. **Monthly Budget Tracking** — $1,000 monthly budget for all AWS services
2. **Proactive Cost Alerts** — Email notifications at 50% and 80% spending thresholds
3. **Forecasted and Actual Alerts** — Early warning when AWS predicts overruns + real-time breach alerts
4. **Resource Tagging Strategy** — Comprehensive approach for identifying resources by environment and team
5. **Cost Allocation Guidance** — Instructions for breaking down costs by environment and team ownership

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                              │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   AWS Budgets                             │   │
│  │  Budget: AdSpark-Monthly-Budget ($1,000/month)           │   │
│  │                                                            │   │
│  │  ┌─────────────────┐         ┌─────────────────┐         │   │
│  │  │  Alert @ 50%    │         │  Alert @ 80%    │         │   │
│  │  │  Forecasted +   │         │  Forecasted +   │         │   │
│  │  │  Actual         │         │  Actual         │         │   │
│  │  └────────┬────────┘         └────────┬────────┘         │   │
│  └───────────┼──────────────────────────┼──────────────────┘   │
│              │                           │                       │
│              ▼                           ▼                       │
│  ┌───────────────────────┐   ┌───────────────────────┐         │
│  │  SNS Topic:           │   │  SNS Topic:           │         │
│  │  budget-alert-50pct   │   │  budget-alert-80pct   │         │
│  └───────────┬───────────┘   └───────────┬───────────┘         │
│              │                           │                       │
│              ▼                           ▼                       │
│  ┌───────────────────────┐   ┌───────────────────────┐         │
│  │  Email Subscription:  │   │  Email Subscriptions: │         │
│  │  finance-alerts@...   │   │  finance-alerts@...   │         │
│  └───────────────────────┘   │  ops-team@...         │         │
│                               └───────────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

Before deploying this infrastructure, ensure you have:

1. **AWS Account** — Active AWS account with billing access
2. **Terraform** — Version 1.0 or higher installed ([Download Terraform](https://www.terraform.io/downloads))
3. **AWS CLI** — Configured with appropriate credentials ([AWS CLI Setup](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html))
4. **IAM Permissions** — Your AWS credentials must have the following permissions:
   - `budgets:CreateBudget`
   - `budgets:ModifyBudget`
   - `budgets:ViewBudget`
   - `sns:CreateTopic`
   - `sns:Subscribe`
   - `sns:GetTopicAttributes`
   - `sns:SetTopicAttributes`

---

## Quick Start

### Step 1: Initialize Terraform

Navigate to the `terraform/task-3/` directory and initialize Terraform:

```bash
cd terraform/task-3
terraform init
```

This will download the required AWS provider plugins.

### Step 2: Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your desired configuration:

```hcl
aws_region = "us-east-1"

budget_name  = "AdSpark-Monthly-Budget"
budget_limit = 1000  # Monthly budget in USD

# Email addresses for 50% threshold alerts (early warning)
alert_emails_50pct = [
  "finance-alerts@adspark.com"
]

# Email addresses for 80% threshold alerts (urgent action)
alert_emails_80pct = [
  "finance-alerts@adspark.com",
  "ops-team@adspark.com"
]

# Common tags for all resources
tags = {
  Environment = "Production"
  Team        = "Finance"
  Project     = "CostControl"
  CostCenter  = "CC-1000"
  ManagedBy   = "Terraform"
}
```

### Step 3: Review the Execution Plan

Preview the resources that will be created:

```bash
terraform plan
```

Expected output:
- 2 SNS topics (one for each threshold)
- Multiple SNS email subscriptions (based on configured emails)
- 1 AWS Budget with 4 notification configurations

### Step 4: Deploy the Infrastructure

Apply the Terraform configuration:

```bash
terraform apply
```

Type `yes` when prompted to confirm resource creation.

### Step 5: Confirm Email Subscriptions

After deployment, AWS will send confirmation emails to all configured addresses. **You must confirm these subscriptions** to receive alerts:

1. Check the inbox for each configured email address
2. Look for emails from "AWS Notifications" with subject: "AWS Notification - Subscription Confirmation"
3. Click the "Confirm subscription" link in each email
4. You should see a confirmation message in your browser

**Important:** Unconfirmed subscriptions will not receive alerts!

### Step 6: Verify Deployment

Check that resources were created successfully:

```bash
# View Terraform outputs
terraform output

# Verify budget in AWS Console
aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text)
```

---

## Resource Tagging Strategy

To meet the business requirement for identifying resources by environment and team, implement the following **mandatory tagging schema** across all AWS resources:

### Mandatory Tags

| Tag Key | Purpose | Example Values |
|---------|---------|----------------|
| `Environment` | Identifies the deployment environment | `Production`, `Development`, `Staging`, `QA` |
| `Team` | Identifies the owning team | `Marketing`, `Analytics`, `Engineering` |
| `Project` | Identifies the associated project | `AdCampaign`, `DataPipeline`, `WebApp` |
| `CostCenter` | For finance/accounting allocation | `CC-1001`, `CC-1002` |

### Example Tag Sets

**Production Analytics Server:**
```json
{
  "Environment": "Production",
  "Team": "Analytics",
  "Project": "DataPipeline",
  "CostCenter": "CC-1002"
}
```

**Development Marketing Application:**
```json
{
  "Environment": "Development",
  "Team": "Marketing",
  "Project": "AdCampaign",
  "CostCenter": "CC-1001"
}
```

### Enforcing the Tagging Policy

To ensure compliance with the tagging strategy:

#### 1. AWS Organizations Tag Policies
Create tag policies to enforce allowed values:

```json
{
  "tags": {
    "Environment": {
      "tag_key": {
        "@@assign": "Environment"
      },
      "tag_value": {
        "@@assign": ["Production", "Development", "Staging", "QA"]
      },
      "enforced_for": {
        "@@assign": ["all"]
      }
    }
  }
}
```

#### 2. AWS Config Rules
Use the `required-tags` managed Config rule:

```bash
aws configservice put-config-rule --config-rule '{
  "ConfigRuleName": "required-tags",
  "Source": {
    "Owner": "AWS",
    "SourceIdentifier": "REQUIRED_TAGS"
  },
  "InputParameters": "{\"tag1Key\":\"Environment\",\"tag2Key\":\"Team\",\"tag3Key\":\"Project\"}",
  "Scope": {
    "ComplianceResourceTypes": ["AWS::EC2::Instance", "AWS::S3::Bucket"]
  }
}'
```

#### 3. IAM Policies
Require tags on resource creation using condition keys:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "ec2:RunInstances",
        "s3:CreateBucket"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotLike": {
          "aws:RequestTag/Environment": ["Production", "Development", "Staging", "QA"],
          "aws:RequestTag/Team": ["Marketing", "Analytics", "Engineering"]
        }
      }
    }
  ]
}
```

#### 4. Service Control Policies (SCPs)
Prevent resource creation without required tags at the organization level:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "Null": {
          "aws:RequestTag/Environment": "true",
          "aws:RequestTag/Team": "true"
        }
      }
    }
  ]
}
```

---

## Activating Cost Allocation Tags

To break down costs by environment and team, you must activate Cost Allocation Tags in the AWS Billing Console.

### Step-by-Step Instructions

#### 1. Navigate to the Billing Console

- Sign in to the AWS Management Console
- Navigate to **AWS Billing** → **Cost Allocation Tags**
- Alternatively, go to: https://console.aws.amazon.com/billing/home#/tags

#### 2. Activate Tags

In the **User-Defined Cost Allocation Tags** section:

1. Search for `Environment` in the tag list
2. Check the box next to `Environment`
3. Search for `Team` in the tag list
4. Check the box next to `Team`
5. Click **Activate** button at the top

#### 3. Wait for Tag Data

- **Wait 24 hours** for tags to appear in Cost Explorer reports
- AWS processes cost allocation tags once per day
- Tags will only apply to costs incurred **after** activation

#### 4. Verify Activation

After 24 hours, verify tags are active:
- Go to **AWS Billing** → **Cost Allocation Tags**
- Confirm `Environment` and `Team` show status: **Active**

---

## Using Cost Explorer for Cost Breakdown

Once Cost Allocation Tags are activated, use **AWS Cost Explorer** to analyze costs by environment and team.

### Accessing Cost Explorer

1. Navigate to **AWS Billing** → **Cost Explorer**
2. Or go to: https://console.aws.amazon.com/cost-management/home#/cost-explorer

### Cost Breakdown by Environment

**View costs grouped by Environment (Production vs. Development):**

1. Click **Launch Cost Explorer**
2. Select date range (e.g., "Last 3 Months")
3. In the **Group by** dropdown, select **Tag** → **Environment**
4. Click **Apply**

This shows a breakdown of costs for each environment:
- Production
- Development
- Staging
- (Untagged resources will appear as "No tag key: Environment")

### Cost Breakdown by Team

**View costs grouped by Team (Marketing, Analytics, Engineering):**

1. In Cost Explorer, select your date range
2. In the **Group by** dropdown, select **Tag** → **Team**
3. Click **Apply**

This shows costs allocated to each team:
- Marketing
- Analytics
- Engineering
- (Untagged resources will appear as "No tag key: Team")

### Advanced Cost Reports

**View Production costs by Team:**

1. Select date range in Cost Explorer
2. Click **Filters** → **Tag** → **Environment** → Select **Production**
3. Change **Group by** to **Tag** → **Team**
4. Click **Apply**

**View Development costs by Team:**

1. Select date range in Cost Explorer
2. Click **Filters** → **Tag** → **Environment** → Select **Development**
3. Change **Group by** to **Tag** → **Team**
4. Click **Apply**

### Sample Cost Report Views

| View | Group By | Filter |
|------|----------|--------|
| Environment Breakdown | Tag: Environment | None |
| Team Breakdown | Tag: Team | None |
| Production by Team | Tag: Team | Environment = Production |
| Development by Team | Tag: Team | Environment = Development |
| Marketing by Environment | Tag: Environment | Team = Marketing |

---

## Testing Budget Alerts

You can test that budget alerts are working without waiting to reach actual spending thresholds.

### Method 1: Adjust Budget Limit (Easiest)

Temporarily lower the budget limit to trigger alerts:

1. Edit `terraform.tfvars` and set `budget_limit = 10` (or current monthly spend)
2. Run `terraform apply` to update the budget
3. Wait a few hours for AWS to recalculate forecasts
4. You should receive alert emails if current/forecasted spending exceeds thresholds
5. Remember to restore the original budget limit afterward

### Method 2: AWS Console Simulation

1. Navigate to **AWS Budgets** in the console
2. Select your budget
3. Observe the current spend vs. budget percentage
4. Alerts will trigger automatically when thresholds are crossed

### Method 3: Increase Actual Spending

**Not recommended for production accounts**, but you can intentionally incur costs:
- Launch temporary EC2 instances
- Transfer large amounts of data out of S3
- Run expensive queries in Athena

**Important:** Remember to clean up test resources to avoid ongoing charges!

---

## Expected Costs

This infrastructure is extremely cost-effective:

| Resource | Cost |
|----------|------|
| **AWS Budgets** | First 2 budgets free, then $0.02/day per budget ≈ $0.60/month |
| **SNS Topics** | Free (first 1,000 notifications/month) |
| **SNS Email Notifications** | Free |
| **Total** | **~$0-0.60/month** |

**Note:** For the first budget in your account, this infrastructure costs **$0** per month.

---

## Outputs

After running `terraform apply`, you'll see the following outputs:

```
budget_id               = "1234567890:AdSpark-Monthly-Budget"
budget_arn              = "arn:aws:budgets::123456789012:budget/AdSpark-Monthly-Budget"
budget_name             = "AdSpark-Monthly-Budget"
sns_topic_50pct_arn     = "arn:aws:sns:us-east-1:123456789012:AdSpark-Monthly-Budget-alert-50pct"
sns_topic_80pct_arn     = "arn:aws:sns:us-east-1:123456789012:AdSpark-Monthly-Budget-alert-80pct"
email_subscriptions_50pct = ["finance-alerts@adspark.com"]
email_subscriptions_80pct = ["finance-alerts@adspark.com", "ops-team@adspark.com"]
budget_summary = {
  name   = "AdSpark-Monthly-Budget"
  limit  = "1000 USD"
  period = "Monthly"
  alerts = {
    threshold_50pct = "Forecasted + Actual"
    threshold_80pct = "Forecasted + Actual"
  }
}
```

These outputs can be used in other Terraform configurations or scripts.

---

## Troubleshooting

### Email Subscriptions Not Receiving Alerts

**Problem:** No alert emails received when budget thresholds are crossed.

**Solution:**
1. Verify email subscriptions are **confirmed** (check AWS SNS console)
2. Check spam/junk folders for AWS notification emails
3. Verify the budget has notifications configured:
   ```bash
   aws budgets describe-budget --account-id $(aws sts get-caller-identity --query Account --output text) --budget-name AdSpark-Monthly-Budget
   ```

### SNS Subscription Shows "PendingConfirmation"

**Problem:** Email subscriptions remain in "PendingConfirmation" status.

**Solution:**
1. Check email inbox (including spam folder) for confirmation email
2. Resend confirmation email from AWS Console: **SNS** → **Subscriptions** → Select subscription → **Request confirmation**
3. If email is not received, verify email address is correct in `terraform.tfvars`

### Budget Alerts Not Triggering

**Problem:** Budget configured but alerts never trigger.

**Solution:**
1. Verify current spend is actually exceeding thresholds
2. Check that **Forecasted** alerts are based on AWS spending predictions (may take a few days to calculate)
3. Ensure SNS topics have correct ARNs in budget notification configuration
4. Verify budget is set to **MONTHLY** period (not QUARTERLY or ANNUALLY)

### Terraform Apply Fails with "AccessDenied"

**Problem:** `terraform apply` fails with IAM permission errors.

**Solution:**
1. Verify your AWS credentials have required permissions (see Prerequisites)
2. Check that you're using the correct AWS account:
   ```bash
   aws sts get-caller-identity
   ```
3. Ensure your IAM user/role has `budgets:*` and `sns:*` permissions

### Tag Not Appearing in Cost Explorer

**Problem:** Cost Allocation Tags not showing in Cost Explorer reports.

**Solution:**
1. Verify tags are **activated** in **Billing Console** → **Cost Allocation Tags**
2. Wait 24 hours after activation for tags to appear
3. Ensure resources are actually tagged with the expected key-value pairs
4. Tags only apply to costs incurred **after** activation

---

## Cleanup

To remove all resources created by this Terraform configuration:

```bash
terraform destroy
```

**Warning:** This will delete the budget, SNS topics, and all subscriptions. Historical budget data will be lost.

---

## Business Requirements Met

This solution addresses all Task 3 requirements:

| Requirement | Solution |
|-------------|----------|
| ✅ Monthly cloud budget of $1,000 | AWS Budget configured with $1,000 limit |
| ✅ Email alert at 50% budget | SNS notifications with forecasted + actual alerts |
| ✅ Email alert at 80% budget | SNS notifications with forecasted + actual alerts |
| ✅ Identify resources by environment/team | Mandatory tagging strategy documented |
| ✅ Cost breakdown by environment | Cost allocation tags activated in Billing Console |
| ✅ Cost breakdown by team | Cost Explorer grouping by Team tag |

---

## Additional Resources

- [AWS Budgets Documentation](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- [AWS SNS Documentation](https://docs.aws.amazon.com/sns/latest/dg/welcome.html)
- [Terraform AWS Provider - Budgets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget)
- [AWS Cost Allocation Tags](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html)
- [AWS Cost Explorer](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html)
