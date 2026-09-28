variable "name_prefix" {
  description = "Prefix applied to every resource name created by the control plane."
  type        = string
}

variable "trusted_principal_arns" {
  description = "Principals allowed to assume the break-glass role. Empty means any principal in this account allowed by its own IAM policy; name specific principals in production."
  type        = list(string)
  default     = []
}

variable "max_session_duration" {
  description = "Maximum break-glass session duration in seconds."
  type        = number
  default     = 3600
}

variable "max_mfa_age_seconds" {
  description = "The caller must have authenticated with MFA within this many seconds."
  type        = number
  default     = 3600
}

variable "log_group_name" {
  description = "CloudWatch log group receiving CloudTrail events, used to detect break-glass use."
  type        = string
}

variable "alarm_topic_arn" {
  description = "SNS topic notified when the break-glass role is used."
  type        = string
}

variable "metric_namespace" {
  description = "CloudWatch namespace for the break-glass usage metric."
  type        = string
  default     = "ControlPlane/Security"
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
