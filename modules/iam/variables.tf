variable "name_prefix" {
  description = "Prefix applied to every resource name created by the control plane."
  type        = string
}

variable "trusted_principal_arns" {
  description = "Principals allowed to assume the admin and security-auditor roles (with MFA). Empty means any principal in this account that is allowed by its own IAM policy."
  type        = list(string)
  default     = []
}

variable "admin_max_session_duration" {
  description = "Maximum session duration in seconds for the admin role."
  type        = number
  default     = 3600
}

variable "auditor_max_session_duration" {
  description = "Maximum session duration in seconds for the security-auditor role."
  type        = number
  default     = 14400
}

variable "github_oidc" {
  description = "GitHub Actions OIDC federation for the workload automation role. subjects are matched against the token's sub claim with StringLike."
  type = object({
    enabled         = optional(bool, false)
    create_provider = optional(bool, true)
    subjects        = optional(list(string), [])
  })
  default = {}
}

variable "boundary_allowed_services" {
  description = "IAM service prefixes workload automation may use (subject to the boundary's explicit denies)."
  type        = list(string)
}

variable "protected_bucket_arns" {
  description = "S3 bucket ARNs holding audit evidence that workload automation must never modify."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key encrypting audit evidence; the security auditor may decrypt with it through S3 only."
  type        = string
}

variable "protected_log_group_arn" {
  description = "ARN of the CloudTrail log group whose filters and retention workload automation must never modify."
  type        = string
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
