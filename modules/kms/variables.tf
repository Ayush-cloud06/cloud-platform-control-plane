variable "name_prefix" {
  description = "Prefix applied to every resource name created by the control plane."
  type        = string
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail trail allowed to encrypt with this key. Used to scope the key policy with aws:SourceArn."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Waiting period before the key is destroyed after deletion is scheduled."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days must be between 7 and 30."
  }
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
