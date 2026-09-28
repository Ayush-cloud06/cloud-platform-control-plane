output "trail_name" {
  description = "Name of the CloudTrail trail."
  value       = aws_cloudtrail.this.name
}

output "trail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = aws_cloudtrail.this.arn
}

output "trail_bucket_name" {
  description = "Name of the S3 bucket holding CloudTrail files."
  value       = aws_s3_bucket.trail.bucket
}

output "trail_bucket_arn" {
  description = "ARN of the S3 bucket holding CloudTrail files."
  value       = aws_s3_bucket.trail.arn
}

output "access_log_bucket_name" {
  description = "Name of the S3 server access log bucket."
  value       = aws_s3_bucket.access_logs.bucket
}

output "access_log_bucket_arn" {
  description = "ARN of the S3 server access log bucket."
  value       = aws_s3_bucket.access_logs.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group receiving CloudTrail events."
  value       = aws_cloudwatch_log_group.trail.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group receiving CloudTrail events."
  value       = aws_cloudwatch_log_group.trail.arn
}
