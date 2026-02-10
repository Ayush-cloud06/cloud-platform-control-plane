# Monthly Budget Alert
resource "aws_budgets_budget" "account_budget" {
  name              = "monthly-total-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit
  limit_unit        = "USD"
  time_period_start = "2026-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }
}

# Cost Anomaly Detector
resource "aws_ce_anomaly_monitor" "service_monitor" {
  name              = "AWSServiceMonitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "email_subscription" {
  name = "DailyAnomalyAlerts"
  threshold_expression {
    dimension {
      key    = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values = ["5.0"] # Alert if a spike is > $5
    }
  }
  frequency        = "DAILY"
  monitor_arn_list = [aws_ce_anomaly_monitor.service_monitor.arn]

  subscriber {
    type    = "EMAIL"
    address = var.notification_email
  }
}
