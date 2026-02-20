/*
Refactor Note:

This repository is designed to function as a reusable, provider-agnostic
landing zone module.

The previous standalone provider configuration (provider.tf) was removed
intentionally to allow the parent/root module to inject the appropriate
AWS provider configuration (e.g., via assume_role for multi-account setups).

This enables:
- Multi-account deployments (security, dev, prod, etc.)
- Provider alias injection from consuming projects
- Proper separation between platform module and environment orchestration

This repository is no longer intended to be executed directly as a
standalone Terraform root. It is consumed by a higher-level landing zone
orchestrator.
*/
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

module "core" {
  source = "./modules/core"

  # pass variables down to the core module
  aws_region           = var.aws_region
  security_alert_email = var.security_alert_email
}

module "siem" {
  source = "./modules/siem"
  count  = var.features.siem_integration ? 1 : 0

  # For now, let's point it to our CloudTrail bucket as a placeholder
  # In a real enterprise, this would be a separate 'Security Account' bucket
  target_bucket_arn = module.core.cloudtrail_bucket_arn
}

module "quotas" {
  source = "./modules/quotas"
  count  = var.features.quotas ? 1 : 0

  vpc_quota = 10
}

module "break_glass" {
  source = "./modules/break_glass"
  count  = var.features.break_glass ? 1 : 0

  break_glass_trusted_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}

module "cost_controls" {
  source = "./modules/cost_controls"
  count  = var.features.cost_controls ? 1 : 0

  notification_email   = var.security_alert_email
  monthly_budget_limit = 20
}
