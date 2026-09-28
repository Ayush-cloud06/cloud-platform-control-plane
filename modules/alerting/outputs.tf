output "topic_arn" {
  description = "ARN of the security alert SNS topic."
  value       = aws_sns_topic.security_alerts.arn
}

output "topic_name" {
  description = "Name of the security alert SNS topic."
  value       = aws_sns_topic.security_alerts.name
}
