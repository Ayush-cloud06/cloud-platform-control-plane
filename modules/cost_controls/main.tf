# Cost signals double as security signals: an unexpected spend spike is often
# the first visible symptom of leaked credentials (crypto-mining, data exfil).

resource "aws_budgets_budget" "monthly" {
  name         = "${var.name_prefix}-monthly-cost"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.notification_emails
  }

  tags = var.tags
}

# AWS permits only one DIMENSIONAL/SERVICE anomaly monitor per account, and
# many accounts already have the default one. Pass its ARN to reuse it.
resource "aws_ce_anomaly_monitor" "services" {
  count = var.existing_anomaly_monitor_arn == null ? 1 : 0

  name              = "${var.name_prefix}-service-spend"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = var.tags
}

resource "aws_ce_anomaly_subscription" "this" {
  name      = "${var.name_prefix}-cost-anomalies"
  frequency = "DAILY"

  monitor_arn_list = [
    coalesce(var.existing_anomaly_monitor_arn, try(aws_ce_anomaly_monitor.services[0].arn, null))
  ]

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = [tostring(var.anomaly_threshold_usd)]
    }
  }

  dynamic "subscriber" {
    for_each = toset(var.notification_emails)
    content {
      type    = "EMAIL"
      address = subscriber.value
    }
  }

  tags = var.tags
}
