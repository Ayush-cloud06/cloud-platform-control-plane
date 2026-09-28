output "alarm_arns" {
  description = "Map of alarm key to CloudWatch alarm ARN."
  value       = { for k, a in aws_cloudwatch_metric_alarm.this : k => a.arn }
}

output "alarm_cis_controls" {
  description = "Map of alarm key to the CIS AWS Foundations v3.0.0 recommendation it implements."
  value       = { for k, v in local.enabled_alarms : k => v.cis }
}

output "available_alarms" {
  description = "Every alarm key this module knows about, for use with disabled_alarms."
  value       = sort(keys(local.alarms))
}
