# Emergency access for when normal access paths (SSO, IdP, admin role) are
# unavailable. The role is deliberately powerful, so the controls are around
# WHO can assume it (named principals, fresh MFA) and making every use LOUD
# (an alarm on any API call made with it). Procedure: docs/runbooks/break-glass.md.

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  trusted_principals = length(var.trusted_principal_arns) > 0 ? var.trusted_principal_arns : [
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

resource "aws_iam_role" "break_glass" {
  name                 = "${var.name_prefix}-break-glass"
  description          = "EMERGENCY USE ONLY. Every API call made with this role raises a security alarm."
  max_session_duration = var.max_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowRecentlyMFAAuthenticatedPrincipals"
      Effect    = "Allow"
      Principal = { AWS = local.trusted_principals }
      Action    = "sts:AssumeRole"
      Condition = {
        Bool            = { "aws:MultiFactorAuthPresent" = "true" }
        NumericLessThan = { "aws:MultiFactorAuthAge" = tostring(var.max_mfa_age_seconds) }
      }
    }]
  })

  tags = merge(var.tags, { "access-tier" = "break-glass" })
}

resource "aws_iam_role_policy_attachment" "break_glass" {
  role       = aws_iam_role.break_glass.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
}

# Matches both the AssumeRole call itself and every action taken with the
# resulting session, so a use is detected even if the AssumeRole event is
# logged in a different region.
resource "aws_cloudwatch_log_metric_filter" "break_glass_used" {
  name           = "${var.name_prefix}-break-glass-used"
  log_group_name = var.log_group_name
  pattern        = "{ ($.userIdentity.sessionContext.sessionIssuer.arn = \"${aws_iam_role.break_glass.arn}\") || (($.eventName = \"AssumeRole\") && ($.requestParameters.roleArn = \"${aws_iam_role.break_glass.arn}\")) }"

  metric_transformation {
    name      = "break-glass-used"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "break_glass_used" {
  alarm_name        = "${var.name_prefix}-break-glass-used"
  alarm_description = "The break-glass role was assumed or used. Confirm an incident ticket exists. Runbook: docs/runbooks/break-glass.md"

  namespace           = var.metric_namespace
  metric_name         = aws_cloudwatch_log_metric_filter.break_glass_used.metric_transformation[0].name
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.alarm_topic_arn]

  tags = var.tags
}
