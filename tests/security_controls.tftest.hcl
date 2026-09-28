# Security properties of each module, asserted directly on the planned
# resources. These are the claims made in docs/compliance-mapping.md; if one
# regresses, CI fails before anything reaches an account.

mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  name_prefix = "cp"
}

# -----------------------------------------------------------------------------
# KMS
# -----------------------------------------------------------------------------

run "kms_key_rotates_and_scopes_cloudtrail" {
  command = apply

  module {
    source = "./modules/kms"
  }

  variables {
    cloudtrail_name = "cp-trail"
  }

  assert {
    condition     = aws_kms_key.this.enable_key_rotation
    error_message = "CIS 3.6: KMS key rotation must be enabled."
  }

  assert {
    condition = one([
      for s in jsondecode(aws_kms_key.this.policy).Statement : s.Condition.StringEquals["aws:SourceArn"]
      if s.Sid == "AllowCloudTrailEncrypt"
    ]) == "arn:aws:cloudtrail:eu-central-1:111122223333:trail/cp-trail"
    error_message = "CloudTrail may only use the key on behalf of this control plane's trail (confused-deputy protection)."
  }
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

run "cloudtrail_is_multi_region_validated_and_encrypted" {
  command = apply

  module {
    source = "./modules/logging"
  }

  variables {
    trail_name  = "cp-trail"
    kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = aws_cloudtrail.this.is_multi_region_trail && aws_cloudtrail.this.include_global_service_events
    error_message = "CIS 3.1: trail must cover all regions and global services."
  }

  assert {
    condition     = aws_cloudtrail.this.enable_log_file_validation
    error_message = "CIS 3.2: log file integrity validation must be enabled."
  }

  assert {
    condition     = aws_cloudtrail.this.kms_key_id == var.kms_key_arn
    error_message = "CIS 3.5: trail must encrypt with the customer-managed key."
  }

  assert {
    condition     = aws_cloudtrail.this.cloud_watch_logs_group_arn != null
    error_message = "Trail must deliver to CloudWatch Logs, otherwise the CIS monitoring alarms see nothing."
  }

  assert {
    condition     = aws_s3_bucket_logging.trail.target_bucket == aws_s3_bucket.access_logs.id
    error_message = "CIS 3.4: trail bucket must have server access logging enabled."
  }

  assert {
    condition     = aws_s3_bucket_versioning.trail.versioning_configuration[0].status == "Enabled"
    error_message = "Trail bucket must be versioned so overwritten or deleted evidence is recoverable."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.trail.block_public_acls,
      aws_s3_bucket_public_access_block.trail.block_public_policy,
      aws_s3_bucket_public_access_block.trail.ignore_public_acls,
      aws_s3_bucket_public_access_block.trail.restrict_public_buckets,
    ])
    error_message = "Trail bucket must block all public access."
  }

  assert {
    condition = anytrue([
      for s in jsondecode(aws_s3_bucket_policy.trail.policy).Statement :
      s.Effect == "Deny" && try(s.Condition.Bool["aws:SecureTransport"], "") == "false"
    ])
    error_message = "CIS 2.1.1: trail bucket must deny non-TLS requests."
  }

  assert {
    condition     = length(aws_s3_bucket_object_lock_configuration.trail) == 0 && !aws_s3_bucket.trail.object_lock_enabled
    error_message = "Object Lock must be opt-in (it is irreversible at bucket level)."
  }
}

run "object_lock_can_be_enabled" {
  command = apply

  module {
    source = "./modules/logging"
  }

  variables {
    trail_name                 = "cp-trail"
    kms_key_arn                = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    object_lock_retention_days = 365
    object_lock_mode           = "COMPLIANCE"
  }

  assert {
    condition     = aws_s3_bucket.trail.object_lock_enabled
    error_message = "Object Lock must be enabled on the bucket when a retention period is set."
  }

  assert {
    condition     = aws_s3_bucket_object_lock_configuration.trail[0].rule[0].default_retention[0].mode == "COMPLIANCE"
    error_message = "Object Lock mode must follow the input."
  }
}

run "archive_must_precede_expiry" {
  command = plan

  module {
    source = "./modules/logging"
  }

  variables {
    trail_name             = "cp-trail"
    kms_key_arn            = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    log_retention_days     = 90
    log_archive_after_days = 90
  }

  expect_failures = [aws_s3_bucket_lifecycle_configuration.trail]
}

# -----------------------------------------------------------------------------
# Alerting
# -----------------------------------------------------------------------------

run "alert_topic_is_encrypted_and_scoped" {
  command = apply

  module {
    source = "./modules/alerting"
  }

  variables {
    kms_key_arn  = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    alert_emails = ["a@example.com", "b@example.com"]
  }

  assert {
    condition     = aws_sns_topic.security_alerts.kms_master_key_id == var.kms_key_arn
    error_message = "Alert topic must be KMS-encrypted."
  }

  assert {
    condition = alltrue([
      for s in jsondecode(aws_sns_topic_policy.security_alerts.policy).Statement :
      s.Principal != "*" if s.Effect == "Allow"
    ])
    error_message = "Alert topic must never allow publishing from an anonymous principal."
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email) == 2
    error_message = "Every alert email must get a subscription."
  }
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

run "every_alarm_notifies_the_alert_topic" {
  command = apply

  module {
    source = "./modules/monitoring"
  }

  variables {
    log_group_name  = "/aws/cloudtrail/cp"
    alarm_topic_arn = "arn:aws:sns:eu-central-1:111122223333:cp-security-alerts"
  }

  assert {
    condition     = alltrue([for a in aws_cloudwatch_metric_alarm.this : contains(a.alarm_actions, var.alarm_topic_arn)])
    error_message = "An alarm without an action is not a control."
  }

  assert {
    condition     = length(regexall("userIdentity.type = \"Root\"", aws_cloudwatch_log_metric_filter.this["root-account-usage"].pattern)) == 1
    error_message = "CIS 4.3: root usage filter must match the Root identity type."
  }

  assert {
    condition     = alltrue([for a in aws_cloudwatch_metric_alarm.this : a.treat_missing_data == "notBreaching"])
    error_message = "Sparse security metrics must not flap into INSUFFICIENT_DATA."
  }
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------

run "human_roles_require_mfa_and_no_ci_role_by_default" {
  command = apply

  module {
    source = "./modules/iam"
  }

  variables {
    boundary_allowed_services = ["ec2", "s3"]
    protected_bucket_arns     = ["arn:aws:s3:::cp-cloudtrail-111122223333-eu-central-1"]
    protected_log_group_arn   = "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/cloudtrail/cp"
    kms_key_arn               = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition = alltrue([
      for role in [aws_iam_role.admin, aws_iam_role.security_auditor] :
      jsondecode(role.assume_role_policy).Statement[0].Condition.Bool["aws:MultiFactorAuthPresent"] == "true"
    ])
    error_message = "Human roles must only be assumable with MFA."
  }

  assert {
    condition     = length(aws_iam_role.workload_automation) == 0
    error_message = "No CI role may exist unless GitHub OIDC is configured."
  }

  assert {
    condition = alltrue(flatten([
      for s in jsondecode(aws_iam_role_policy.security_auditor_evidence.policy).Statement : [
        for a in flatten([s.Action]) :
        can(regex("^(s3:(Get|List)|kms:Decrypt$|logs:(Describe|Filter|Get|StartQuery|StopQuery))", a))
      ]
    ]))
    error_message = "The auditor's evidence policy must stay read-only."
  }

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.workload_boundary.policy).Statement :
      s.Effect == "Deny" && contains(s.Action, "iam:*")
    ])
    error_message = "Workload boundary must deny all IAM actions (privilege escalation)."
  }

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.workload_boundary.policy).Statement :
      s.Effect == "Deny" && contains(s.Action, "cloudtrail:StopLogging")
    ])
    error_message = "Workload boundary must deny disabling CloudTrail."
  }

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.workload_boundary.policy).Statement :
      s.Effect == "Deny" && contains(s.Action, "s3:DeleteObject") && contains(try(tolist(s.Resource), []), "arn:aws:s3:::cp-cloudtrail-111122223333-eu-central-1/*")
    ])
    error_message = "Workload boundary must protect audit evidence objects from deletion."
  }

  assert {
    condition = one([
      for s in jsondecode(aws_iam_policy.workload_boundary.policy).Statement : s.Action
      if s.Sid == "AllowListedWorkloadServices"
    ]) == ["ec2:*", "s3:*"]
    error_message = "Boundary allow list must be generated exactly from boundary_allowed_services."
  }
}

run "github_oidc_role_is_pinned_to_audience_and_subject" {
  command = apply

  module {
    source = "./modules/iam"
  }

  variables {
    boundary_allowed_services = ["ec2"]
    protected_bucket_arns     = ["arn:aws:s3:::cp-cloudtrail-111122223333-eu-central-1"]
    protected_log_group_arn   = "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/cloudtrail/cp"
    kms_key_arn               = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    github_oidc = {
      enabled  = true
      subjects = ["repo:example-org/workloads:environment:production"]
    }
  }

  assert {
    condition     = jsondecode(aws_iam_role.workload_automation[0].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com"
    error_message = "OIDC trust must pin the audience to STS."
  }

  assert {
    condition     = jsondecode(aws_iam_role.workload_automation[0].assume_role_policy).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"] == ["repo:example-org/workloads:environment:production"]
    error_message = "OIDC trust must pin the subject to the configured repository and environment."
  }

  assert {
    condition     = aws_iam_role.workload_automation[0].permissions_boundary == aws_iam_policy.workload_boundary.arn
    error_message = "The CI role must be capped by the workload boundary."
  }
}

run "existing_github_oidc_provider_can_be_reused" {
  command = apply

  module {
    source = "./modules/iam"
  }

  variables {
    boundary_allowed_services = ["ec2"]
    protected_bucket_arns     = ["arn:aws:s3:::cp-cloudtrail-111122223333-eu-central-1"]
    protected_log_group_arn   = "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/cloudtrail/cp"
    kms_key_arn               = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    github_oidc = {
      enabled         = true
      create_provider = false
      subjects        = ["repo:example-org/workloads:ref:refs/heads/main"]
    }
  }

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 0
    error_message = "An account-wide OIDC provider must not be created twice."
  }
}

# -----------------------------------------------------------------------------
# Guardrails
# -----------------------------------------------------------------------------

run "account_guardrails_are_secure_by_default" {
  command = apply

  module {
    source = "./modules/guardrails"
  }

  assert {
    condition     = aws_s3_account_public_access_block.this.block_public_policy && aws_s3_account_public_access_block.this.restrict_public_buckets
    error_message = "CIS 2.1.4: account-level S3 Block Public Access must be on."
  }

  assert {
    condition     = aws_ebs_encryption_by_default.this.enabled
    error_message = "CIS 2.2.1: EBS encryption by default must be on."
  }

  assert {
    condition     = aws_iam_account_password_policy.this.minimum_password_length >= 14 && aws_iam_account_password_policy.this.password_reuse_prevention >= 24
    error_message = "CIS 1.8/1.9: password policy must require 14+ characters and prevent reuse."
  }

  assert {
    condition     = aws_accessanalyzer_analyzer.this.type == "ACCOUNT"
    error_message = "CIS 1.20: IAM Access Analyzer must be enabled."
  }
}

# -----------------------------------------------------------------------------
# Break glass
# -----------------------------------------------------------------------------

run "break_glass_requires_fresh_mfa_and_is_loud" {
  command = apply

  module {
    source = "./modules/break_glass"
  }

  variables {
    log_group_name  = "/aws/cloudtrail/cp"
    alarm_topic_arn = "arn:aws:sns:eu-central-1:111122223333:cp-security-alerts"
  }

  assert {
    condition     = jsondecode(aws_iam_role.break_glass.assume_role_policy).Statement[0].Condition.Bool["aws:MultiFactorAuthPresent"] == "true"
    error_message = "Break-glass must require MFA."
  }

  assert {
    condition     = jsondecode(aws_iam_role.break_glass.assume_role_policy).Statement[0].Condition.NumericLessThan["aws:MultiFactorAuthAge"] == "3600"
    error_message = "Break-glass must require a recent MFA authentication."
  }

  assert {
    condition     = strcontains(aws_cloudwatch_log_metric_filter.break_glass_used.pattern, aws_iam_role.break_glass.arn)
    error_message = "Break-glass usage filter must match this role's ARN."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.break_glass_used.threshold == 1 && contains(aws_cloudwatch_metric_alarm.break_glass_used.alarm_actions, var.alarm_topic_arn)
    error_message = "A single break-glass use must page the alert topic."
  }
}

# -----------------------------------------------------------------------------
# SIEM
# -----------------------------------------------------------------------------

run "siem_pipeline_is_encrypted_and_least_privilege" {
  command = apply

  module {
    source = "./modules/siem"
  }

  variables {
    source_log_group_name  = "/aws/cloudtrail/cp"
    kms_key_arn            = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    access_log_bucket_name = "cp-access-logs-111122223333-eu-central-1"
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.server_side_encryption[0].enabled && aws_kinesis_firehose_delivery_stream.this.server_side_encryption[0].key_type == "CUSTOMER_MANAGED_CMK"
    error_message = "Firehose stream must be encrypted with the customer-managed key."
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.extended_s3_configuration[0].bucket_arn == aws_s3_bucket.staging.arn
    error_message = "SIEM export must land in its own staging bucket, never in the audit evidence bucket."
  }

  assert {
    condition = alltrue(flatten([
      for s in jsondecode(aws_iam_role_policy.firehose.policy).Statement : [
        for a in s.Action : !endswith(a, ":*")
      ]
    ]))
    error_message = "Firehose role must not use service-wide wildcards."
  }

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.this.destination_arn == aws_kinesis_firehose_delivery_stream.this.arn
    error_message = "CloudTrail log group must stream into the SIEM Firehose."
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.staging.rule[0].expiration[0].days == 30
    error_message = "SIEM staging data must expire (data minimisation)."
  }
}

# -----------------------------------------------------------------------------
# Quota monitoring / threat detection / cost controls
# -----------------------------------------------------------------------------

run "quota_alarms_compare_usage_against_service_quota" {
  command = apply

  module {
    source = "./modules/quota_monitoring"
  }

  variables {
    alarm_topic_arn = "arn:aws:sns:eu-central-1:111122223333:cp-security-alerts"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.vcpu_quota_utilization) == 3
    error_message = "Standard, G and P vCPU classes must be monitored by default."
  }

  assert {
    condition = alltrue([
      for a in aws_cloudwatch_metric_alarm.vcpu_quota_utilization :
      anytrue([for q in a.metric_query : strcontains(coalesce(q.expression, "-"), "SERVICE_QUOTA(usage)")])
    ])
    error_message = "Alarms must measure utilization relative to the live service quota."
  }
}

run "guardduty_high_severity_findings_are_routed" {
  command = apply

  module {
    source = "./modules/threat_detection"
  }

  variables {
    alarm_topic_arn = "arn:aws:sns:eu-central-1:111122223333:cp-security-alerts"
  }

  assert {
    condition     = aws_guardduty_detector.this.enable
    error_message = "GuardDuty detector must be enabled."
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.guardduty_findings.event_pattern).detail.severity[0].numeric == [">=", 7]
    error_message = "Only High and Critical findings should page by default."
  }

  assert {
    condition     = aws_cloudwatch_event_target.guardduty_to_sns.arn == var.alarm_topic_arn
    error_message = "Findings must be delivered to the alert topic."
  }
}

run "cost_controls_reuse_existing_anomaly_monitor" {
  command = apply

  module {
    source = "./modules/cost_controls"
  }

  variables {
    notification_emails          = ["finops@example.com"]
    existing_anomaly_monitor_arn = "arn:aws:ce::111122223333:anomalymonitor/11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = length(aws_ce_anomaly_monitor.services) == 0
    error_message = "Must not create a second SERVICE monitor (AWS allows only one per account)."
  }

  assert {
    condition     = aws_ce_anomaly_subscription.this.monitor_arn_list[0] == var.existing_anomaly_monitor_arn
    error_message = "Anomaly subscription must use the existing monitor."
  }

  assert {
    condition     = length(aws_budgets_budget.monthly.notification) == 2
    error_message = "Budget must alert on actual (80%) and forecasted (100%) spend."
  }
}
