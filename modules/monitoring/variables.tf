variable "name_prefix" {
  description = "Prefix applied to every resource name created by the control plane."
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group receiving the multi-region CloudTrail events."
  type        = string
}

variable "alarm_topic_arn" {
  description = "SNS topic that alarms notify."
  type        = string
}

variable "metric_namespace" {
  description = "CloudWatch namespace for the security metrics."
  type        = string
  default     = "ControlPlane/Security"
}

variable "disabled_alarms" {
  description = "Alarm keys to skip (e.g. [\"organizations-changes\"] in an account that is not an Organizations management account)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
