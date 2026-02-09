# Central SNS topic for all security-related alerts.

resource "aws_sns_topic" "security_alerts" {
  name = "security-alerts"
}

# optional : Emain subscription 

variable "security_alert_email" {
  description = "Email address to receive security alerts"
  type        = string
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_alert_email
}
