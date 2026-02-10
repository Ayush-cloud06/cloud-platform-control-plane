variable "aws_region" {
  description = "AWS Region to deploy to"
  type        = string
  default     = "ap-south-1"
}

variable "security_alert_email" {
  description = "Email for security notifications"
  type        = string
}

variable "features" {
  description = "Feature flags to enable/disable specific security modules"
  type        = map(bool)
  default = {
    siem_integration = false
    quotas           = true
    break_glass      = true
    cost_controls    = false
  }
}
