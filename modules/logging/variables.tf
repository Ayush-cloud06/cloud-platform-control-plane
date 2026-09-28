variable "name_prefix" {
  description = "Prefix applied to every resource name created by the control plane."
  type        = string
}

variable "trail_name" {
  description = "Name of the CloudTrail trail. Must match the name the KMS key policy is scoped to."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt CloudTrail files, the trail bucket and the log group."
  type        = string
}

variable "log_retention_days" {
  description = "Days CloudTrail files and S3 access logs are retained in S3 before expiry."
  type        = number
  default     = 365
}

variable "log_archive_after_days" {
  description = "Days after which CloudTrail files transition to S3 Glacier Instant Retrieval."
  type        = number
  default     = 90
}

variable "cloudwatch_log_retention_days" {
  description = "Retention of the CloudTrail CloudWatch log group. Must be a value CloudWatch Logs accepts."
  type        = number
  default     = 365
}

variable "object_lock_retention_days" {
  description = "Default S3 Object Lock retention for CloudTrail files. 0 disables Object Lock. Can only be enabled when the bucket is first created."
  type        = number
  default     = 0
}

variable "object_lock_mode" {
  description = "S3 Object Lock mode: GOVERNANCE (bypassable with s3:BypassGovernanceRetention) or COMPLIANCE (irreversible)."
  type        = string
  default     = "GOVERNANCE"
}

variable "force_destroy" {
  description = "Allow Terraform to delete non-empty log buckets. Only for disposable sandbox accounts."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
