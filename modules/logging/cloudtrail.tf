# -----------------------------------------------------------------------------
# CloudWatch Logs delivery: the hot tier that powers metric-filter alarms
# (modules/monitoring) and SIEM streaming (modules/siem).
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "trail" {
  name              = "/aws/cloudtrail/${var.name_prefix}"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name        = "${var.name_prefix}-cloudtrail-to-cloudwatch"
  description = "Lets CloudTrail deliver events to the ${aws_cloudwatch_log_group.trail.name} log group."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceArn" = local.trail_arn }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch" {
  name = "deliver-to-log-group"
  role = aws_iam_role.cloudtrail_to_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.trail.arn}:log-stream:*"
    }]
  })
}

# -----------------------------------------------------------------------------
# The trail
# -----------------------------------------------------------------------------

resource "aws_cloudtrail" "this" {
  #checkov:skip=CKV_AWS_252:Per-log-file SNS notifications are noise; security signal is delivered via metric-filter alarms.
  name           = local.trail_name
  s3_bucket_name = aws_s3_bucket.trail.id
  kms_key_id     = var.kms_key_arn

  is_multi_region_trail         = true # CIS AWS 3.1
  include_global_service_events = true
  enable_log_file_validation    = true # CIS AWS 3.2
  enable_logging                = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cloudwatch.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = var.tags

  # CloudTrail validates bucket and role access at creation time.
  depends_on = [
    aws_s3_bucket_policy.trail,
    aws_iam_role_policy.cloudtrail_to_cloudwatch,
  ]
}
