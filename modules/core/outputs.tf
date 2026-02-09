output "security_alerts_topic_arn" {
  value       = module.alerts.topic_arn
  description = "SNS topic ARN for all security alerts"
}
