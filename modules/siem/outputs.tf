output "delivery_stream_arn" {
  description = "ARN of the Firehose delivery stream."
  value       = aws_kinesis_firehose_delivery_stream.this.arn
}

output "staging_bucket_name" {
  description = "Name of the S3 bucket the SIEM ingests from."
  value       = aws_s3_bucket.staging.bucket
}

output "staging_bucket_arn" {
  description = "ARN of the S3 bucket the SIEM ingests from."
  value       = aws_s3_bucket.staging.arn
}
