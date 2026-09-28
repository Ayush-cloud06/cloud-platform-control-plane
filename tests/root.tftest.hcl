# Root module wiring: feature flags, defaults and input validation.
# Runs fully offline against a mocked AWS provider: `terraform test`.

mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  environment  = "test"
  alert_emails = ["secops@example.com"]
}

run "core_only_by_default" {
  command = apply

  assert {
    condition     = alltrue([for _, enabled in output.enabled_features : !enabled])
    error_message = "All optional features must default to off (core-only 'startup mode')."
  }

  assert {
    condition     = length(output.security_alarms) == 15
    error_message = "All 15 CIS AWS v3.0.0 section 4 monitoring alarms must be deployed by default."
  }

  assert {
    condition     = output.security_alarms["root-account-usage"] == "4.3"
    error_message = "Root account usage alarm must map to CIS 4.3."
  }

  assert {
    condition     = output.break_glass_role_arn == null && output.siem_staging_bucket_name == null && output.guardduty_detector_id == null
    error_message = "Optional modules must not be created when their flags are off."
  }

  assert {
    condition     = output.workload_automation_role_arn == null
    error_message = "No CI role may exist unless GitHub OIDC is explicitly configured."
  }

  assert {
    condition     = output.cloudtrail_bucket_name == "cp-cloudtrail-111122223333-eu-central-1"
    error_message = "Trail bucket name must be derived from prefix, account and region."
  }
}

run "all_features_enabled" {
  command = apply

  variables {
    features = {
      break_glass      = true
      siem_integration = true
      cost_controls    = true
      quota_monitoring = true
      threat_detection = true
    }
    github_oidc = {
      enabled  = true
      subjects = ["repo:example-org/workloads:ref:refs/heads/main"]
    }
  }

  assert {
    condition     = output.break_glass_role_arn != null
    error_message = "break_glass flag must create the break-glass role."
  }

  assert {
    condition     = output.siem_staging_bucket_name != null
    error_message = "siem_integration flag must create the SIEM pipeline."
  }

  assert {
    condition     = output.guardduty_detector_id != null
    error_message = "threat_detection flag must create the GuardDuty detector."
  }

  assert {
    condition     = output.workload_automation_role_arn != null
    error_message = "GitHub OIDC configuration must create the workload automation role."
  }
}

run "partial_feature_map_is_accepted" {
  command = plan

  variables {
    features = { break_glass = true }
  }

  assert {
    condition     = output.enabled_features.break_glass && !output.enabled_features.siem_integration
    error_message = "Omitted feature flags must default to false instead of failing."
  }
}

run "rejects_invalid_email" {
  command = plan

  variables {
    alert_emails = ["not-an-email"]
  }

  expect_failures = [var.alert_emails]
}

run "rejects_empty_alert_recipients" {
  command = plan

  variables {
    alert_emails = []
  }

  expect_failures = [var.alert_emails]
}

run "rejects_wildcard_github_subject" {
  command = plan

  variables {
    github_oidc = {
      enabled  = true
      subjects = ["repo:*"]
    }
  }

  expect_failures = [var.github_oidc]
}

run "rejects_oidc_without_subjects" {
  command = plan

  variables {
    github_oidc = { enabled = true }
  }

  expect_failures = [var.github_oidc]
}

run "rejects_iam_in_boundary_allow_list" {
  command = plan

  variables {
    boundary_allowed_services = ["ec2", "iam"]
  }

  expect_failures = [var.boundary_allowed_services]
}

run "rejects_disabling_root_usage_alarm" {
  command = plan

  variables {
    disabled_security_alarms = ["root-account-usage"]
  }

  expect_failures = [var.disabled_security_alarms]
}

run "allows_disabling_noisy_alarm" {
  command = plan

  variables {
    disabled_security_alarms = ["organizations-changes"]
  }

  assert {
    condition     = length(output.security_alarms) == 14 && !contains(keys(output.security_alarms), "organizations-changes")
    error_message = "Disabled alarms must be removed from the deployment."
  }
}

run "rejects_invalid_name_prefix" {
  command = plan

  variables {
    name_prefix = "Invalid_Prefix"
  }

  expect_failures = [var.name_prefix]
}

run "rejects_unsupported_log_retention" {
  command = plan

  variables {
    cloudwatch_log_retention_days = 100
  }

  expect_failures = [var.cloudwatch_log_retention_days]
}
