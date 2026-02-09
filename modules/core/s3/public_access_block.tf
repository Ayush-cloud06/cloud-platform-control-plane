# Account-wide S3 public access block.
# This prevents any bucket in this AWS account from being made public,
# even if someone tries through Terraform, Console, or CLI.

resource "aws_s3_account_public_access_block" "account" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
