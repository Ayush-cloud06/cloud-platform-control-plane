module "core" {
  source = "./modules/core"

  # pass variables down to the core module
  aws_region           = var.aws_region
  security_alert_email = var.security_alert_email
}
