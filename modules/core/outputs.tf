output "security_alerts_topic_arn" {
  value       = module.alerts.topic_arn
  description = "SNS topic ARN for all security alerts"
}

output "cloudtrail_bucket_arn" {
  value       = module.logging.bucket_arn
  description = "The ARN of the CloudTrail bucket passed up from the logging module"
}
