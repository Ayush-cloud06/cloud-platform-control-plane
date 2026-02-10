# IAM role for Firehose to write to s3
resource "aws_iam_role" "firehose_role" {
  name = "siem-firehose-delivery-role"

  assume_role_policy = jsonencode({
    Version = "2012=10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
    }]
  })
}

# The Delivery Stream
resource "aws_kinesis_firehose_delivery_stream" "siem_stream" {
  name        = "security-logs-to-siem"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = var.target_bucket_arn

    # Enable GZIP compression to save on SIEM storage costs
    compression_format = "GZIP"
  }
}
