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

# SNS Topic for 50% Budget Alert
resource "aws_sns_topic" "budget_alert_50pct" {
  name         = "${var.budget_name}-alert-50pct"
  display_name = "AdSpark Budget Alert - 50% Threshold"

  tags = merge(
    var.tags,
    {
      Name      = "${var.budget_name}-alert-50pct"
      Threshold = "50%"
    }
  )
}

# SNS Topic for 80% Budget Alert
resource "aws_sns_topic" "budget_alert_80pct" {
  name         = "${var.budget_name}-alert-80pct"
  display_name = "AdSpark Budget Alert - 80% Threshold"

  tags = merge(
    var.tags,
    {
      Name      = "${var.budget_name}-alert-80pct"
      Threshold = "80%"
    }
  )
}

# SNS Email Subscriptions for 50% Threshold
resource "aws_sns_topic_subscription" "budget_alert_50pct_emails" {
  for_each = toset(var.alert_emails_50pct)

  topic_arn = aws_sns_topic.budget_alert_50pct.arn
  protocol  = "email"
  endpoint  = each.value
}

# SNS Email Subscriptions for 80% Threshold
resource "aws_sns_topic_subscription" "budget_alert_80pct_emails" {
  for_each = toset(var.alert_emails_80pct)

  topic_arn = aws_sns_topic.budget_alert_80pct.arn
  protocol  = "email"
  endpoint  = each.value
}

# AWS Budget with Cost Alerts
resource "aws_budgets_budget" "monthly_budget" {
  name              = var.budget_name
  budget_type       = "COST"
  limit_amount      = tostring(var.budget_limit)
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  # 50% Threshold - Forecasted Alert
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alert_50pct.arn]
  }

  # 50% Threshold - Actual Alert
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alert_50pct.arn]
  }

  # 80% Threshold - Forecasted Alert
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alert_80pct.arn]
  }

  # 80% Threshold - Actual Alert
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alert_80pct.arn]
  }

  tags = merge(
    var.tags,
    {
      Name = var.budget_name
    }
  )
}
