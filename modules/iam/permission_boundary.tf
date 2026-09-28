# Permission boundary for workload automation.
#
# The effective permissions of a role are the INTERSECTION of its identity
# policies and its boundary. So even though the workload automation role has
# PowerUserAccess attached, it can never:
#
#   1. act outside the allow-listed services,
#   2. touch identity or account control (no privilege escalation path),
#   3. blind the organisation by disabling security telemetry, or
#   4. tamper with the control plane's own evidence and detective controls.
#
# Statements 3 and 4 are explicit Denies, so they hold even if the allow list
# is widened later.

locals {
  alarm_arn_pattern = "arn:${local.partition}:cloudwatch:${local.region}:${local.account_id}:alarm:${var.name_prefix}-*"
}

resource "aws_iam_policy" "workload_boundary" {
  name        = "${var.name_prefix}-workload-boundary"
  description = "Caps workload automation: allow-listed services only, no IAM, no tampering with security telemetry or control plane resources."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowListedWorkloadServices"
        Effect   = "Allow"
        Action   = [for svc in var.boundary_allowed_services : "${svc}:*"]
        Resource = "*"
      },
      {
        Sid    = "DenyIdentityAndAccountControl"
        Effect = "Deny"
        Action = [
          "iam:*",
          "organizations:*",
          "account:*",
          "sts:AssumeRole", # no role chaining out of the boundary
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyDisablingSecurityTelemetry"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail",
          "cloudtrail:PutEventSelectors",
          "guardduty:DeleteDetector",
          "guardduty:UpdateDetector",
          "guardduty:DisassociateFromMasterAccount",
          "guardduty:DisassociateFromAdministratorAccount",
          "config:DeleteConfigurationRecorder",
          "config:DeleteDeliveryChannel",
          "config:StopConfigurationRecorder",
          "securityhub:DisableSecurityHub",
          "access-analyzer:DeleteAnalyzer",
          "ec2:DisableEbsEncryptionByDefault",
          "s3:PutAccountPublicAccessBlock",
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyTamperingWithAuditEvidence"
        Effect = "Deny"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:PutBucketAcl",
          "s3:PutBucketVersioning",
          "s3:PutLifecycleConfiguration",
          "s3:PutBucketLogging",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketObjectLockConfiguration",
          "s3:PutBucketPublicAccessBlock",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:BypassGovernanceRetention",
        ]
        Resource = flatten([
          for arn in var.protected_bucket_arns : [arn, "${arn}/*"]
        ])
      },
      {
        Sid    = "DenyTamperingWithDetectiveControls"
        Effect = "Deny"
        Action = [
          "logs:DeleteLogGroup",
          "logs:DeleteMetricFilter",
          "logs:PutMetricFilter",
          "logs:PutRetentionPolicy",
          "logs:DeleteSubscriptionFilter",
          "logs:PutSubscriptionFilter",
          "logs:DisassociateKmsKey",
        ]
        Resource = [var.protected_log_group_arn, "${var.protected_log_group_arn}:*"]
      },
      {
        Sid    = "DenyTamperingWithSecurityAlarms"
        Effect = "Deny"
        Action = [
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DisableAlarmActions",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:SetAlarmState",
        ]
        Resource = local.alarm_arn_pattern
      },
    ]
  })

  tags = var.tags
}
