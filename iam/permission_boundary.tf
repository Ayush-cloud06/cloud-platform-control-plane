# This permission boundary is attached to automation roles (Terraform / CI / Lambda).
# It acts as a hard safety cage:
#
# Even if the role is given AdministratorAccess, it can NEVER:
# - Modify IAM (no users, roles, policies, or privilege escalation)
# - Touch AWS Organizations
# - Disable security logging (CloudTrail, GuardDuty, Config)
# - Break account-level visibility

resource "aws_iam_policy" "permission_boundary" {
  name        = "automation-permission-boundary"
  description = "Limits what automation roles can ever do, even with admin policies attached."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Allow normal infrastructure work
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "rds:*",
          "vpc:*",
          "cloudwatch:*",
          "logs:*",
          "elasticloadbalancing:*",
          "autoscaling:*"
        ]
        Resource = "*"
      },

      # Explicitly deny identity and account control
      {
        Effect = "Deny"
        Action = [
          "iam:*",
          "organizations:*",
          "account:*",
          "sts:AssumeRole"
        ]
        Resource = "*"
      },

      # Prevent disabling security visibility
      {
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "guardduty:DeleteDetector",
          "guardduty:UpdateDetector",
          "config:DeleteConfigurationRecorder",
          "config:StopConfigurationRecorder"
        ]
        Resource = "*"
      }
    ]
  })
}
