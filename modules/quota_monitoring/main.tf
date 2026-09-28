# Alarms when EC2 vCPU usage approaches the account's service quota.
#
# Service Quotas can only RAISE limits, never lower them, so they cannot be
# used as a preventive "cap". Preventive limits belong in SCPs at the
# Organizations level. What quotas CAN do is act as a tripwire: a sudden climb
# toward the vCPU quota (GPU families especially) is the classic footprint of
# compromised credentials being used for crypto-mining.
# See docs/adr/0004-quota-monitoring-not-enforcement.md.

resource "aws_cloudwatch_metric_alarm" "vcpu_quota_utilization" {
  for_each = toset(var.vcpu_classes)

  alarm_name        = "${var.name_prefix}-vcpu-quota-${lower(replace(each.value, "/", "-"))}"
  alarm_description = "EC2 ${each.value} vCPU usage is above ${var.utilization_threshold_percent}% of the service quota. Unexpected growth can indicate credential abuse. Runbook: docs/runbooks/security-alarm-response.md"

  comparison_operator = "GreaterThanThreshold"
  threshold           = var.utilization_threshold_percent
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "utilization"
    expression  = "(usage / SERVICE_QUOTA(usage)) * 100"
    label       = "vCPU quota utilization (%)"
    return_data = true
  }

  metric_query {
    id = "usage"

    metric {
      namespace   = "AWS/Usage"
      metric_name = "ResourceCount"
      period      = 300
      stat        = "Maximum"

      dimensions = {
        Service  = "EC2"
        Type     = "Resource"
        Resource = "vCPU"
        Class    = each.value
      }
    }
  }

  alarm_actions = [var.alarm_topic_arn]

  tags = var.tags
}
