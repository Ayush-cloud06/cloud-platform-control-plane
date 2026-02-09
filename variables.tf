variable "aws_region" {
  description = "AWS Region to deploy to"
  type        = string
  default     = "ap-south-1"
}

variable "security_alert_email" {
  description = "Email for security notifications"
  type        = string
  default     = "example@gmail.com"
}
