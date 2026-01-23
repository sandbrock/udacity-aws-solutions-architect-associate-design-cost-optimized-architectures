# Budget Outputs
output "budget_id" {
  description = "The ID of the created AWS Budget"
  value       = aws_budgets_budget.monthly_budget.id
}

output "budget_arn" {
  description = "The ARN of the created AWS Budget"
  value       = aws_budgets_budget.monthly_budget.arn
}

output "budget_name" {
  description = "The name of the created AWS Budget"
  value       = aws_budgets_budget.monthly_budget.name
}

# SNS Topic Outputs
output "sns_topic_50pct_arn" {
  description = "The ARN of the SNS topic for 50% budget threshold alerts"
  value       = aws_sns_topic.budget_alert_50pct.arn
}

output "sns_topic_80pct_arn" {
  description = "The ARN of the SNS topic for 80% budget threshold alerts"
  value       = aws_sns_topic.budget_alert_80pct.arn
}

output "sns_topic_50pct_name" {
  description = "The name of the SNS topic for 50% budget threshold alerts"
  value       = aws_sns_topic.budget_alert_50pct.name
}

output "sns_topic_80pct_name" {
  description = "The name of the SNS topic for 80% budget threshold alerts"
  value       = aws_sns_topic.budget_alert_80pct.name
}

# Email Subscription Outputs
output "email_subscriptions_50pct" {
  description = "List of email addresses subscribed to 50% threshold alerts"
  value       = var.alert_emails_50pct
}

output "email_subscriptions_80pct" {
  description = "List of email addresses subscribed to 80% threshold alerts"
  value       = var.alert_emails_80pct
}

# Configuration Summary
output "budget_summary" {
  description = "Summary of the budget configuration"
  value = {
    name   = aws_budgets_budget.monthly_budget.name
    limit  = "${var.budget_limit} USD"
    period = "Monthly"
    alerts = {
      threshold_50pct = "Forecasted + Actual"
      threshold_80pct = "Forecasted + Actual"
    }
  }
}
