module "core" {
  source = "./modules/core"

  # pass variables down to the core module
  aws_region           = var.aws_region
  security_alert_email = var.security_alert_email
}

module "siem" {
  source = "./modules/siem"
  count  = var.features.siem_integration ? 1 : 0
}

module "quotas" {
  source = "./modules/quotas"
  count  = var.features.quotas ? 1 : 0

  vpc_quota = 10
}

module "break_glass" {
  source = "./modules/break_glass"
  count  = var.features.break_glass ? 1 : 0
}

module "cost_controls" {
  source = "./modules/cost_controls"
  count  = var.features.cost_controls ? 1 : 0
}
