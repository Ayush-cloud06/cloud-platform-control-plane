# Account-level secure defaults. Each of these is a single switch that closes
# an entire class of misconfiguration for every resource created later.

# CIS AWS 2.1.4: no bucket in this account can be made public, whatever its
# own bucket policy or ACL says.
resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CIS AWS 2.2.1: every new EBS volume and snapshot copy is encrypted.
# This setting is regional; it applies to the provider's region only.
resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}

# CIS AWS 1.8 / 1.9: only matters if someone creates an IAM user despite the
# role-only design, so it is a backstop rather than the primary control.
# No forced expiry, in line with NIST SP 800-63B.
resource "aws_iam_account_password_policy" "this" {
  #checkov:skip=CKV_AWS_9:Forced periodic rotation is intentionally omitted per NIST SP 800-63B 5.1.1.2; CIS AWS v3.0.0 does not require it.
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
}

# CIS AWS 1.20: continuously flags resources shared outside the account
# (S3, KMS, IAM roles, Lambda, SQS, Secrets Manager, ...). No additional cost.
resource "aws_accessanalyzer_analyzer" "this" {
  analyzer_name = "${var.name_prefix}-external-access"
  type          = "ACCOUNT"

  tags = var.tags
}
