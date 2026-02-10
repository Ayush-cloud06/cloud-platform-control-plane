variable "monthly_budget_limit" {
  description = "The montly spend limit in USD"
  type        = number
  default     = 10
}

variable "notification_email" {
  description = "Email add. for cost alerts"
  type        = string
}
