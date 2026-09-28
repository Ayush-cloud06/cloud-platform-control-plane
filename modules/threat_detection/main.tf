# Amazon GuardDuty: managed threat detection over CloudTrail, VPC Flow Logs and
# DNS logs, without having to run or tune the collectors yourself.
# High-severity findings are routed to the same alert topic as everything else.
#
# GuardDuty findings are regional and delivered to EventBridge in the region
# that produced them, so an EventBridge rule is the right tool here (unlike the
# CloudTrail alarms, see docs/adr/0002-metric-filters-over-eventbridge.md).

resource "aws_guardduty_detector" "this" {
  #checkov:skip=CKV2_AWS_3:Single-account scope by design; Organizations-wide delegated administration is on the roadmap.
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.name_prefix}-guardduty-findings"
  description = "GuardDuty findings with severity >= ${var.min_severity}."

  event_pattern = jsonencode({
    source        = ["aws.guardduty"]
    "detail-type" = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", var.min_severity] }]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "security-alerts"
  arn       = var.alarm_topic_arn

  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      type        = "$.detail.type"
      title       = "$.detail.title"
      account     = "$.detail.accountId"
      region      = "$.detail.region"
      finding_id  = "$.detail.id"
      resource    = "$.detail.resource.resourceType"
      description = "$.detail.description"
    }
    input_template = "\"GuardDuty <severity> | <type> | <title> | account <account> <region> | resource <resource> | finding <finding_id> | <description>\""
  }
}
