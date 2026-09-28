variable "name_prefix" {
  description = "Prefix applied to every resource name created by the control plane."
  type        = string
}

variable "alarm_topic_arn" {
  description = "SNS topic notified when quota utilization crosses the threshold."
  type        = string
}

variable "vcpu_classes" {
  description = "EC2 vCPU usage classes to watch (AWS/Usage 'Class' dimension). G and P are GPU families favoured for crypto-mining."
  type        = list(string)
  default     = ["Standard/OnDemand", "G/OnDemand", "P/OnDemand"]
}

variable "utilization_threshold_percent" {
  description = "Alarm when usage exceeds this percentage of the quota."
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
