output "budget_name" {
  description = "Name of the monthly cost budget."
  value       = aws_budgets_budget.monthly.name
}

output "anomaly_monitor_arn" {
  description = "ARN of the cost anomaly monitor in use."
  value       = coalesce(var.existing_anomaly_monitor_arn, try(aws_ce_anomaly_monitor.services[0].arn, null))
}
