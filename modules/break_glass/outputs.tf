output "role_arn" {
  description = "ARN of the break-glass role."
  value       = aws_iam_role.break_glass.arn
}

output "alarm_arn" {
  description = "ARN of the alarm raised whenever the break-glass role is used."
  value       = aws_cloudwatch_metric_alarm.break_glass_used.arn
}
