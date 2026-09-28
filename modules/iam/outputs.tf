output "admin_role_arn" {
  description = "ARN of the MFA-protected admin role."
  value       = aws_iam_role.admin.arn
}

output "security_auditor_role_arn" {
  description = "ARN of the MFA-protected security auditor role."
  value       = aws_iam_role.security_auditor.arn
}

output "workload_automation_role_arn" {
  description = "ARN of the GitHub OIDC workload automation role, or null when OIDC is disabled."
  value       = try(aws_iam_role.workload_automation[0].arn, null)
}

output "workload_boundary_policy_arn" {
  description = "ARN of the workload permission boundary. Attach it to any role created for workloads."
  value       = aws_iam_policy.workload_boundary.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider, or null when OIDC is disabled."
  value       = local.github_oidc_provider_arn
}
