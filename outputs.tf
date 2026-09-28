output "enabled_features" {
  description = "Resolved feature flags, including defaults."
  value       = var.features
}

output "kms_key_arn" {
  description = "KMS key protecting security telemetry."
  value       = module.kms.key_arn
}

output "cloudtrail_arn" {
  description = "ARN of the multi-region CloudTrail trail."
  value       = module.logging.trail_arn
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket holding CloudTrail audit evidence."
  value       = module.logging.trail_bucket_name
}

output "cloudtrail_log_group_name" {
  description = "CloudWatch log group receiving CloudTrail events."
  value       = module.logging.log_group_name
}

output "security_alerts_topic_arn" {
  description = "SNS topic receiving every security alarm and finding."
  value       = module.alerting.topic_arn
}

output "security_alarms" {
  description = "CIS monitoring alarms deployed, keyed by name, with the CIS recommendation each implements."
  value       = module.monitoring.alarm_cis_controls
}

output "admin_role_arn" {
  description = "MFA-protected admin role."
  value       = module.iam.admin_role_arn
}

output "security_auditor_role_arn" {
  description = "MFA-protected security auditor role."
  value       = module.iam.security_auditor_role_arn
}

output "workload_automation_role_arn" {
  description = "GitHub OIDC workload automation role (null when disabled). Use as role-to-assume in aws-actions/configure-aws-credentials."
  value       = module.iam.workload_automation_role_arn
}

output "workload_boundary_policy_arn" {
  description = "Permission boundary to attach to workload roles."
  value       = module.iam.workload_boundary_policy_arn
}

output "break_glass_role_arn" {
  description = "Break-glass role (null when disabled)."
  value       = try(module.break_glass[0].role_arn, null)
}

output "siem_staging_bucket_name" {
  description = "Bucket the SIEM ingests from (null when disabled)."
  value       = try(module.siem[0].staging_bucket_name, null)
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID (null when disabled)."
  value       = try(module.threat_detection[0].detector_id, null)
}
