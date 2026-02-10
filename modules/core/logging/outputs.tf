output "bucket_arn" {
  value       = aws_s3_bucket.cloudtrail_bucket.arn
  description = "The ARN of the S3 bucket storing CloudTrail logs"
}
