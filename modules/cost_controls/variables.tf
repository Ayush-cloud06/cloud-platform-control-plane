variable "name_prefix" {
  description = "Prefix applied to every resource name created by the control plane."
  type        = string
}

variable "notification_emails" {
  description = "Email addresses notified about budget thresholds and cost anomalies."
  type        = list(string)
}

variable "monthly_budget_limit_usd" {
  description = "Monthly spend limit in USD. Alerts fire at 80% actual and 100% forecasted."
  type        = number
  default     = 50
}

variable "anomaly_threshold_usd" {
  description = "Minimum total impact in USD for a cost anomaly to trigger a notification."
  type        = number
  default     = 10
}

variable "existing_anomaly_monitor_arn" {
  description = "ARN of an existing DIMENSIONAL/SERVICE cost anomaly monitor to reuse instead of creating one."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
