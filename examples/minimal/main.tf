# Core baseline only: identity, CloudTrail + KMS, CIS monitoring alarms,
# alerting and account guardrails. A few USD per month in a quiet account
# (KMS key, 15 alarms, CloudWatch Logs ingestion of management events).

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      owner = "platform-security"
    }
  }
}

module "control_plane" {
  source = "../.."

  environment  = "sandbox"
  alert_emails = var.alert_emails

  # Disposable account: allow `terraform destroy` to remove log buckets.
  force_destroy_buckets = true
}

variable "aws_region" {
  description = "Region to deploy the control plane into."
  type        = string
  default     = "eu-central-1"
}

variable "alert_emails" {
  description = "Recipients of security alerts."
  type        = list(string)
}

output "security_alerts_topic_arn" {
  description = "Confirm the email subscription sent to this topic."
  value       = module.control_plane.security_alerts_topic_arn
}

output "admin_role_arn" {
  description = "Assume with MFA for administrative work."
  value       = module.control_plane.admin_role_arn
}
