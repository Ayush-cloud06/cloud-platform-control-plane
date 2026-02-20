variable "aws_region" {
  description = "AWS Region to deploy to"
  type        = string
  default     = "ap-south-1"
}

variable "security_alert_email" {
  description = "Email for security notifications"
  type        = string
  default     = "test-admin@example.com"
}

variable "features" {
  description = "Feature flags to enable/disable specific security modules"
  type        = map(bool)
  default = {
    siem_integration = true
    quotas           = true
    break_glass      = true
    cost_controls    = true
  }
}


variable "environment" {
  description = "Environment name (security, dev, prod)"
  type        = string
}
