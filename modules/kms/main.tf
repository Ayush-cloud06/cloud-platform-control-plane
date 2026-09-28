# Customer-managed key for all security telemetry produced by the control plane:
# CloudTrail log files, the CloudTrail CloudWatch log group, the security alert
# SNS topic and the SIEM staging pipeline.
#
# One key (rather than one per service) keeps cost and key-policy sprawl low
# while still giving an auditable, rotatable, revocable boundary around audit
# data. See docs/adr/0005-single-cmk-for-security-telemetry.md.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
  partition  = data.aws_partition.current.partition

  trail_arn = "arn:${local.partition}:cloudtrail:${local.region}:${local.account_id}:trail/${var.cloudtrail_name}"
}

resource "aws_kms_key" "this" {
  description             = "${var.name_prefix}: encryption key for security telemetry (CloudTrail, CloudWatch Logs, SNS, SIEM)"
  enable_key_rotation     = true
  deletion_window_in_days = var.deletion_window_in_days

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Delegates key administration and usage to IAM policies in this
        # account. Without this statement the key becomes unmanageable.
        Sid       = "EnableIAMPolicies"
        Effect    = "Allow"
        Principal = { AWS = "arn:${local.partition}:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudTrailEncrypt"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:GenerateDataKey*"
        Resource  = "*"
        Condition = {
          StringEquals = { "aws:SourceArn" = local.trail_arn }
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:${local.partition}:cloudtrail:*:${local.account_id}:trail/*"
          }
        }
      },
      {
        Sid       = "AllowCloudTrailDescribeKey"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:DescribeKey"
        Resource  = "*"
        Condition = {
          StringEquals = { "aws:SourceArn" = local.trail_arn }
        }
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = "logs.${local.region}.amazonaws.com" }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*",
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:*"
          }
        }
      },
      {
        # CloudWatch alarms and EventBridge must be able to publish to the
        # KMS-encrypted SNS topic. Who may publish is governed by the topic
        # policy; this statement only permits the cryptographic operations.
        Sid    = "AllowAlertPublishersToUseEncryptedTopic"
        Effect = "Allow"
        Principal = {
          Service = ["cloudwatch.amazonaws.com", "events.amazonaws.com"]
        }
        Action   = ["kms:Decrypt", "kms:GenerateDataKey*"]
        Resource = "*"
      },
    ]
  })

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}-security-telemetry"
  target_key_id = aws_kms_key.this.key_id
}
