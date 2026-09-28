locals {
  trail_name = "${var.name_prefix}-trail"

  tags = merge(
    {
      "managed-by"  = "terraform"
      "project"     = "cloud-platform-control-plane"
      "environment" = var.environment
    },
    var.tags,
  )
}

# =============================================================================
# CORE BASELINE (always on)
# Identity, audit logging, detection and account guardrails. These are not
# feature-flagged: an account without them is not a governed account.
# =============================================================================

module "kms" {
  source = "./modules/kms"

  name_prefix     = var.name_prefix
  cloudtrail_name = local.trail_name
  tags            = local.tags
}

module "logging" {
  source = "./modules/logging"

  name_prefix                   = var.name_prefix
  trail_name                    = local.trail_name
  kms_key_arn                   = module.kms.key_arn
  log_retention_days            = var.log_retention_days
  log_archive_after_days        = var.log_archive_after_days
  cloudwatch_log_retention_days = var.cloudwatch_log_retention_days
  object_lock_retention_days    = var.object_lock_retention_days
  object_lock_mode              = var.object_lock_mode
  force_destroy                 = var.force_destroy_buckets
  tags                          = local.tags
}

module "alerting" {
  source = "./modules/alerting"

  name_prefix  = var.name_prefix
  kms_key_arn  = module.kms.key_arn
  alert_emails = var.alert_emails
  tags         = local.tags
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix      = var.name_prefix
  log_group_name   = module.logging.log_group_name
  alarm_topic_arn  = module.alerting.topic_arn
  metric_namespace = var.metric_namespace
  disabled_alarms  = var.disabled_security_alarms
  tags             = local.tags
}

module "iam" {
  source = "./modules/iam"

  name_prefix               = var.name_prefix
  trusted_principal_arns    = var.trusted_principal_arns
  github_oidc               = var.github_oidc
  boundary_allowed_services = var.boundary_allowed_services
  protected_bucket_arns = compact([
    module.logging.trail_bucket_arn,
    module.logging.access_log_bucket_arn,
    try(module.siem[0].staging_bucket_arn, ""),
  ])
  protected_log_group_arn = module.logging.log_group_arn
  kms_key_arn             = module.kms.key_arn
  tags                    = local.tags
}

module "guardrails" {
  source = "./modules/guardrails"

  name_prefix = var.name_prefix
  tags        = local.tags
}

# =============================================================================
# OPTIONAL CAPABILITIES (feature flags)
# =============================================================================

module "break_glass" {
  source = "./modules/break_glass"
  count  = var.features.break_glass ? 1 : 0

  name_prefix            = var.name_prefix
  trusted_principal_arns = var.break_glass_trusted_principal_arns
  log_group_name         = module.logging.log_group_name
  alarm_topic_arn        = module.alerting.topic_arn
  metric_namespace       = var.metric_namespace
  tags                   = local.tags
}

module "siem" {
  source = "./modules/siem"
  count  = var.features.siem_integration ? 1 : 0

  name_prefix            = var.name_prefix
  source_log_group_name  = module.logging.log_group_name
  kms_key_arn            = module.kms.key_arn
  access_log_bucket_name = module.logging.access_log_bucket_name
  retention_days         = var.siem_retention_days
  force_destroy          = var.force_destroy_buckets
  tags                   = local.tags
}

module "cost_controls" {
  source = "./modules/cost_controls"
  count  = var.features.cost_controls ? 1 : 0

  name_prefix                  = var.name_prefix
  notification_emails          = var.alert_emails
  monthly_budget_limit_usd     = var.monthly_budget_limit_usd
  anomaly_threshold_usd        = var.cost_anomaly_threshold_usd
  existing_anomaly_monitor_arn = var.existing_anomaly_monitor_arn
  tags                         = local.tags
}

module "quota_monitoring" {
  source = "./modules/quota_monitoring"
  count  = var.features.quota_monitoring ? 1 : 0

  name_prefix                   = var.name_prefix
  alarm_topic_arn               = module.alerting.topic_arn
  utilization_threshold_percent = var.vcpu_quota_threshold_percent
  tags                          = local.tags
}

module "threat_detection" {
  source = "./modules/threat_detection"
  count  = var.features.threat_detection ? 1 : 0

  name_prefix     = var.name_prefix
  alarm_topic_arn = module.alerting.topic_arn
  min_severity    = var.guardduty_min_severity
  tags            = local.tags
}
