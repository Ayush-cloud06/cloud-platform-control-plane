# IAM Foundation (Roles & Root Protection)
module "iam" {
  source = "./iam"
}

# Logging & CloudTrail
module "logging" {
  source = "./logging"
}

# S3 Guardrails (Public Access Block)
module "s3" {
  source = "./s3"
}

# Security Alerts (SNS)
module "alerts" {
  source               = "./alerts"
  security_alert_email = var.security_alert_email
}
