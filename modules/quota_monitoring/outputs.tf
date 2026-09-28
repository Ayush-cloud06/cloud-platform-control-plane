output "alarm_arns" {
  description = "Map of vCPU class to CloudWatch alarm ARN."
  value       = { for k, a in aws_cloudwatch_metric_alarm.vcpu_quota_utilization : k => a.arn }
}
