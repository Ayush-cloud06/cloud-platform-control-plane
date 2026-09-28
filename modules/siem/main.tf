# SIEM export pipeline:
#
#   CloudTrail log group --subscription filter--> Kinesis Data Firehose --> S3 staging bucket
#
# The staging bucket is the hand-off point for a SIEM (Splunk, Datadog, Elastic,
# Sentinel, Security Lake) to ingest from, typically via an S3-SQS pull
# integration. It is deliberately separate from the CloudTrail evidence bucket
# so SIEM tooling never needs write access to audit evidence.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
  partition  = data.aws_partition.current.partition

  bucket_name = "${var.name_prefix}-siem-staging-${local.account_id}-${local.region}"
  stream_name = "${var.name_prefix}-siem-export"
}

# -----------------------------------------------------------------------------
# Staging bucket
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "staging" {
  #checkov:skip=CKV_AWS_144:Staging data is transient and re-derivable from CloudTrail; replication is not warranted.
  #checkov:skip=CKV2_AWS_62:Notifications are configured by the consuming SIEM integration, not by this module.
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "staging" {
  bucket = aws_s3_bucket.staging.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "staging" {
  bucket = aws_s3_bucket.staging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "staging" {
  bucket = aws_s3_bucket.staging.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "staging" {
  bucket = aws_s3_bucket.staging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_logging" "staging" {
  bucket        = aws_s3_bucket.staging.id
  target_bucket = var.access_log_bucket_name
  target_prefix = "${local.bucket_name}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "staging" {
  bucket = aws_s3_bucket.staging.id

  rule {
    id     = "expire-siem-staging"
    status = "Enabled"

    filter {}

    expiration {
      days = var.retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  depends_on = [aws_s3_bucket_versioning.staging]
}

resource "aws_s3_bucket_policy" "staging" {
  bucket = aws_s3_bucket.staging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.staging.arn, "${aws_s3_bucket.staging.arn}/*"]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.staging]
}

# -----------------------------------------------------------------------------
# Firehose delivery stream
# -----------------------------------------------------------------------------

resource "aws_iam_role" "firehose" {
  name        = "${var.name_prefix}-siem-firehose"
  description = "Lets Firehose write SIEM export objects to the staging bucket."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "firehose" {
  name = "write-staging-bucket"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteStagingBucket"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
        ]
        Resource = [aws_s3_bucket.staging.arn, "${aws_s3_bucket.staging.arn}/*"]
      },
      {
        Sid      = "EncryptViaS3Only"
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource = var.kms_key_arn
        Condition = {
          StringEquals = { "kms:ViaService" = "s3.${local.region}.amazonaws.com" }
          StringLike   = { "kms:EncryptionContext:aws:s3:arn" = "${aws_s3_bucket.staging.arn}/*" }
        }
      },
    ]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = local.stream_name
  destination = "extended_s3"

  server_side_encryption {
    enabled  = true
    key_type = "CUSTOMER_MANAGED_CMK"
    key_arn  = var.kms_key_arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.staging.arn

    prefix              = "cloudtrail/!{timestamp:yyyy/MM/dd}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd}/"

    buffering_size     = 5
    buffering_interval = 300

    # CloudWatch Logs already gzips subscription payloads; compressing again
    # would double-wrap them. Objects land as gzip regardless.
    compression_format = "UNCOMPRESSED"
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy.firehose]
}

# -----------------------------------------------------------------------------
# CloudWatch Logs -> Firehose subscription
# -----------------------------------------------------------------------------

resource "aws_iam_role" "logs_to_firehose" {
  name        = "${var.name_prefix}-siem-logs-to-firehose"
  description = "Lets CloudWatch Logs push subscription data into the SIEM Firehose stream."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "logs.${local.region}.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringLike = { "aws:SourceArn" = "arn:${local.partition}:logs:${local.region}:${local.account_id}:*" }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "logs_to_firehose" {
  name = "put-records"
  role = aws_iam_role.logs_to_firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"]
      Resource = aws_kinesis_firehose_delivery_stream.this.arn
    }]
  })
}

resource "aws_cloudwatch_log_subscription_filter" "this" {
  name            = "${var.name_prefix}-siem-export"
  log_group_name  = var.source_log_group_name
  filter_pattern  = var.filter_pattern
  destination_arn = aws_kinesis_firehose_delivery_stream.this.arn
  role_arn        = aws_iam_role.logs_to_firehose.arn

  depends_on = [aws_iam_role_policy.logs_to_firehose]
}
