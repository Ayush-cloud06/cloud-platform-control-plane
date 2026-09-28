variable "name_prefix" {
  description = "Prefix applied to every resource name created by the control plane."
  type        = string
}

variable "source_log_group_name" {
  description = "CloudWatch log group to stream to the SIEM (the CloudTrail log group)."
  type        = string
}

variable "filter_pattern" {
  description = "CloudWatch Logs filter pattern selecting which events are exported. Empty string exports everything."
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "KMS key used to encrypt the Firehose stream and staging bucket."
  type        = string
}

variable "access_log_bucket_name" {
  description = "Bucket receiving S3 server access logs for the staging bucket."
  type        = string
}

variable "retention_days" {
  description = "Days SIEM export objects are kept in the staging bucket. The SIEM is the system of record for this data."
  type        = number
  default     = 30
}

variable "force_destroy" {
  description = "Allow Terraform to delete the staging bucket when it still contains objects."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
