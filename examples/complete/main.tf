# Every capability enabled, configured the way a regulated production
# account would run it.

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      owner       = "platform-security"
      cost-center = "security"
    }
  }
}

module "control_plane" {
  source = "../.."

  name_prefix  = "acme-prod"
  environment  = "prod"
  alert_emails = var.alert_emails

  features = {
    break_glass      = true
    siem_integration = true
    cost_controls    = true
    quota_monitoring = true
    threat_detection = true
  }

  # Identity
  trusted_principal_arns             = var.trusted_principal_arns
  break_glass_trusted_principal_arns = var.break_glass_trusted_principal_arns
  github_oidc = {
    enabled  = true
    subjects = ["repo:${var.github_repository}:environment:production"]
  }

  # Evidence retention: 1 year hot + WORM protection.
  log_retention_days         = 400
  object_lock_retention_days = 365
  object_lock_mode           = "GOVERNANCE"

  # Spend guardrails
  monthly_budget_limit_usd   = 500
  cost_anomaly_threshold_usd = 25
}

variable "aws_region" {
  description = "Region to deploy the control plane into."
  type        = string
  default     = "eu-central-1"
}

variable "alert_emails" {
  description = "Recipients of security alerts and cost notifications."
  type        = list(string)
}

variable "trusted_principal_arns" {
  description = "Principals (e.g. IdP-federated roles) allowed to assume admin and auditor roles."
  type        = list(string)
  default     = []
}

variable "break_glass_trusted_principal_arns" {
  description = "Named principals allowed to assume the break-glass role."
  type        = list(string)
  default     = []
}

variable "github_repository" {
  description = "GitHub repository (owner/name) whose production environment deploys workloads."
  type        = string
}

output "control_plane" {
  description = "Key control plane identifiers."
  value = {
    cloudtrail_bucket            = module.control_plane.cloudtrail_bucket_name
    security_alerts_topic_arn    = module.control_plane.security_alerts_topic_arn
    workload_automation_role_arn = module.control_plane.workload_automation_role_arn
    break_glass_role_arn         = module.control_plane.break_glass_role_arn
    siem_staging_bucket          = module.control_plane.siem_staging_bucket_name
    security_alarms              = module.control_plane.security_alarms
  }
}
