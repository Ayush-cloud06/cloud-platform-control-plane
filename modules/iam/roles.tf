data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
  partition  = data.aws_partition.current.partition

  # Default to the account itself, meaning "any IAM principal in this account
  # whose identity policy allows sts:AssumeRole on this role". Pass explicit
  # principal ARNs (e.g. an IdP-federated role) to narrow this further.
  human_trusted_principals = length(var.trusted_principal_arns) > 0 ? var.trusted_principal_arns : [
    "arn:${local.partition}:iam::${local.account_id}:root"
  ]

  human_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowMFAAuthenticatedPrincipals"
      Effect    = "Allow"
      Principal = { AWS = local.human_trusted_principals }
      Action    = "sts:AssumeRole"
      Condition = {
        Bool = { "aws:MultiFactorAuthPresent" = "true" }
      }
    }]
  })
}

# -----------------------------------------------------------------------------
# Human roles. No IAM users are created: people assume roles, with MFA.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "admin" {
  name                 = "${var.name_prefix}-admin"
  description          = "Human administrators. Requires MFA."
  assume_role_policy   = local.human_trust_policy
  max_session_duration = var.admin_max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "security_auditor" {
  name                 = "${var.name_prefix}-security-auditor"
  description          = "Read-only security review and audit evidence collection. Requires MFA."
  assume_role_policy   = local.human_trust_policy
  max_session_duration = var.auditor_max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "security_auditor" {
  role       = aws_iam_role.security_auditor.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/SecurityAudit"
}

# SecurityAudit covers configuration reads but not the audit data itself.
# This grants exactly what evidence collection needs: read CloudTrail files
# (and digests, for `aws cloudtrail validate-logs`) and query the trail's log
# group. Read-only; no write or delete on any evidence.
resource "aws_iam_role_policy" "security_auditor_evidence" {
  name = "read-audit-evidence"
  role = aws_iam_role.security_auditor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadEvidenceBuckets"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket", "s3:ListBucketVersions"]
        Resource = flatten([for arn in var.protected_bucket_arns : [arn, "${arn}/*"]])
      },
      {
        Sid      = "DecryptEvidenceViaS3"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = var.kms_key_arn
        Condition = {
          StringEquals = { "kms:ViaService" = "s3.${local.region}.amazonaws.com" }
        }
      },
      {
        Sid    = "QueryTrailLogGroup"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents",
          "logs:GetLogEvents",
          "logs:StartQuery",
        ]
        Resource = [var.protected_log_group_arn, "${var.protected_log_group_arn}:*"]
      },
      {
        # These Logs Insights actions do not support resource-level permissions.
        Sid      = "ReadQueryResults"
        Effect   = "Allow"
        Action   = ["logs:GetQueryResults", "logs:StopQuery"]
        Resource = "*"
      },
    ]
  })
}

# -----------------------------------------------------------------------------
# Workload automation role, federated from GitHub Actions via OIDC.
# Short-lived credentials only; no access keys exist to leak.
# See docs/adr/0003-github-oidc-for-ci.md.
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  count = var.github_oidc.enabled && var.github_oidc.create_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # AWS validates GitHub's certificate against its own trusted CA library, but
  # older provider versions still require a thumbprint to be supplied.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]

  tags = var.tags
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.github_oidc.enabled && !var.github_oidc.create_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"
}

locals {
  github_oidc_provider_arn = !var.github_oidc.enabled ? null : (
    var.github_oidc.create_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
  )
}

resource "aws_iam_role" "workload_automation" {
  count = var.github_oidc.enabled ? 1 : 0

  name                 = "${var.name_prefix}-workload-automation"
  description          = "CI/CD for workload infrastructure. Federated from GitHub Actions; capped by the workload permission boundary."
  max_session_duration = 3600
  permissions_boundary = aws_iam_policy.workload_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowGitHubActionsOIDC"
      Effect    = "Allow"
      Principal = { Federated = local.github_oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = var.github_oidc.subjects }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "workload_automation" {
  count = var.github_oidc.enabled ? 1 : 0

  role       = aws_iam_role.workload_automation[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/PowerUserAccess"
}
