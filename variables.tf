# -----------------------------------------------------------------------------
# Required
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment this account serves (e.g. security, dev, prod). Applied as a tag."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,31}$", var.environment))
    error_message = "environment must be 2-32 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "alert_emails" {
  description = "Email addresses that receive security alerts and cost notifications. Each must confirm the SNS subscription."
  type        = list(string)

  validation {
    condition     = length(var.alert_emails) > 0
    error_message = "At least one alert email is required: an alarm nobody receives is not a control."
  }

  validation {
    condition     = alltrue([for e in var.alert_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])
    error_message = "Every entry in alert_emails must be a valid email address."
  }
}

# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for every resource name. Lets several control plane instances coexist and keeps bucket names within S3 limits."
  type        = string
  default     = "cp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,18}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 2-20 lowercase letters, digits or hyphens, start with a letter and not end with a hyphen."
  }
}

variable "tags" {
  description = "Additional tags applied to every taggable resource."
  type        = map(string)
  default     = {}
}

variable "features" {
  description = "Feature flags for the optional capabilities. The core baseline is always deployed. Omitted flags default to false."
  type = object({
    break_glass      = optional(bool, false)
    siem_integration = optional(bool, false)
    cost_controls    = optional(bool, false)
    quota_monitoring = optional(bool, false)
    threat_detection = optional(bool, false)
  })
  default = {}
}

variable "force_destroy_buckets" {
  description = "Allow Terraform to delete non-empty log buckets on destroy. Only for disposable sandbox accounts; never for accounts under audit."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Days CloudTrail files are retained in S3."
  type        = number
  default     = 365

  validation {
    condition     = var.log_retention_days >= 90
    error_message = "log_retention_days must be at least 90 days to support incident investigation."
  }
}

variable "log_archive_after_days" {
  description = "Days after which CloudTrail files move to S3 Glacier Instant Retrieval. Must be lower than log_retention_days."
  type        = number
  default     = 90

  validation {
    condition     = var.log_archive_after_days >= 30
    error_message = "log_archive_after_days must be at least 30."
  }
}

variable "cloudwatch_log_retention_days" {
  description = "Retention of the CloudTrail CloudWatch log group (the searchable hot tier)."
  type        = number
  default     = 365

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_log_retention_days)
    error_message = "cloudwatch_log_retention_days must be a retention value supported by CloudWatch Logs."
  }
}

variable "object_lock_retention_days" {
  description = "S3 Object Lock (WORM) default retention for CloudTrail files. 0 disables it. Can only be turned on when the bucket is first created."
  type        = number
  default     = 0

  validation {
    condition     = var.object_lock_retention_days >= 0
    error_message = "object_lock_retention_days cannot be negative."
  }
}

variable "object_lock_mode" {
  description = "S3 Object Lock mode. GOVERNANCE can be bypassed by privileged principals; COMPLIANCE cannot be shortened or removed by anyone, including root."
  type        = string
  default     = "GOVERNANCE"

  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.object_lock_mode)
    error_message = "object_lock_mode must be GOVERNANCE or COMPLIANCE."
  }
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

variable "metric_namespace" {
  description = "CloudWatch namespace for control plane security metrics."
  type        = string
  default     = "ControlPlane/Security"
}

variable "disabled_security_alarms" {
  description = "CIS monitoring alarms to skip, by key. See the monitoring module's available_alarms output."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([for a in var.disabled_security_alarms : contains([
      "unauthorized-api-calls", "console-signin-without-mfa", "root-account-usage", "iam-policy-changes",
      "cloudtrail-config-changes", "console-authentication-failures", "kms-key-disable-or-deletion",
      "s3-bucket-policy-changes", "config-changes", "security-group-changes", "nacl-changes",
      "network-gateway-changes", "route-table-changes", "vpc-changes", "organizations-changes",
    ], a)])
    error_message = "disabled_security_alarms contains an unknown alarm key."
  }

  validation {
    condition     = !contains(var.disabled_security_alarms, "root-account-usage") && !contains(var.disabled_security_alarms, "cloudtrail-config-changes")
    error_message = "root-account-usage and cloudtrail-config-changes are non-negotiable and cannot be disabled."
  }
}

# -----------------------------------------------------------------------------
# Identity
# -----------------------------------------------------------------------------

variable "trusted_principal_arns" {
  description = "Principals allowed to assume the admin and security-auditor roles (MFA always required). Empty trusts IAM principals in this account."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for a in var.trusted_principal_arns : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:", a))])
    error_message = "trusted_principal_arns must contain IAM ARNs."
  }
}

variable "github_oidc" {
  description = "GitHub Actions OIDC federation for the workload automation role. Set create_provider = false if the account already has the GitHub OIDC provider."
  type = object({
    enabled         = optional(bool, false)
    create_provider = optional(bool, true)
    subjects        = optional(list(string), [])
  })
  default = {}

  validation {
    condition     = !var.github_oidc.enabled || length(var.github_oidc.subjects) > 0
    error_message = "github_oidc.subjects must list at least one subject when OIDC is enabled."
  }

  validation {
    # Owner and repository must be literal: a wildcard there would let any
    # GitHub repository assume the role.
    condition     = alltrue([for s in var.github_oidc.subjects : can(regex("^repo:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+:.+$", s))])
    error_message = "Each GitHub OIDC subject must look like repo:<owner>/<repo>:<qualifier> with no wildcard in owner or repository."
  }
}

variable "boundary_allowed_services" {
  description = "IAM service prefixes that workload automation may use. Identity, account and security-telemetry actions are always denied."
  type        = list(string)
  default     = ["ec2", "s3", "rds", "cloudwatch", "logs", "elasticloadbalancing", "autoscaling"]

  validation {
    condition     = length(setintersection(var.boundary_allowed_services, ["*", "iam", "organizations", "account", "sts"])) == 0
    error_message = "boundary_allowed_services cannot include *, iam, organizations, account or sts."
  }
}

variable "break_glass_trusted_principal_arns" {
  description = "Principals allowed to assume the break-glass role. Name specific principals in production."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for a in var.break_glass_trusted_principal_arns : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:", a))])
    error_message = "break_glass_trusted_principal_arns must contain IAM ARNs."
  }
}

# -----------------------------------------------------------------------------
# Optional capability settings
# -----------------------------------------------------------------------------

variable "siem_retention_days" {
  description = "Days SIEM export objects are kept in the staging bucket."
  type        = number
  default     = 30

  validation {
    condition     = var.siem_retention_days >= 1
    error_message = "siem_retention_days must be at least 1."
  }
}

variable "monthly_budget_limit_usd" {
  description = "Monthly budget in USD. Alerts at 80% actual and 100% forecasted spend."
  type        = number
  default     = 50

  validation {
    condition     = var.monthly_budget_limit_usd > 0
    error_message = "monthly_budget_limit_usd must be positive."
  }
}

variable "cost_anomaly_threshold_usd" {
  description = "Minimum total impact in USD for a cost anomaly alert."
  type        = number
  default     = 10

  validation {
    condition     = var.cost_anomaly_threshold_usd > 0
    error_message = "cost_anomaly_threshold_usd must be positive."
  }
}

variable "existing_anomaly_monitor_arn" {
  description = "Reuse an existing DIMENSIONAL/SERVICE cost anomaly monitor (AWS allows only one per account)."
  type        = string
  default     = null
}

variable "vcpu_quota_threshold_percent" {
  description = "Alarm when EC2 vCPU usage exceeds this percentage of the service quota."
  type        = number
  default     = 80

  validation {
    condition     = var.vcpu_quota_threshold_percent > 0 && var.vcpu_quota_threshold_percent <= 100
    error_message = "vcpu_quota_threshold_percent must be between 1 and 100."
  }
}

variable "guardduty_min_severity" {
  description = "Minimum GuardDuty finding severity sent to the alert topic."
  type        = number
  default     = 7

  validation {
    condition     = var.guardduty_min_severity >= 1 && var.guardduty_min_severity <= 10
    error_message = "guardduty_min_severity must be between 1 and 10."
  }
}
