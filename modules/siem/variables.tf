variable "target_bucket_arn" {
  description = "The ARN of the central S3 bucket for SIEM log integration"
  type        = string
}

variable "log_retention_days" {
  description = "How long to keep logs in SIEM buffers"
  type        = number
  default     = 60
}
