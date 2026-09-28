variable "name_prefix" {
  description = "Prefix applied to every resource name created by the control plane."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the SNS topic."
  type        = string
}

variable "alert_emails" {
  description = "Email addresses subscribed to the security alert topic."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
