variable "security_alert_email" {
  description = "Email address to receive security alerts"
  type        = string
}


variable "aws_region" {
  description = "AWS region for the landing zone"
  type        = string
  default     = "ap-south-1" # Change as needed
}
