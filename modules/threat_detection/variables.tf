variable "name_prefix" {
  description = "Prefix applied to every resource name created by the control plane."
  type        = string
}

variable "alarm_topic_arn" {
  description = "SNS topic receiving GuardDuty findings."
  type        = string
}

variable "min_severity" {
  description = "Minimum GuardDuty severity routed to the alert topic (Low 1-3.9, Medium 4-6.9, High 7-8.9, Critical 9-10)."
  type        = number
  default     = 7
}

variable "finding_publishing_frequency" {
  description = "How often updated findings are exported: FIFTEEN_MINUTES, ONE_HOUR or SIX_HOURS."
  type        = string
  default     = "FIFTEEN_MINUTES"
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
