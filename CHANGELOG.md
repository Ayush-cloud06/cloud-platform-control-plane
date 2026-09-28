# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-09-28

A ground-up rework of the prototype into a tested, documented, audit-traceable module. **Breaking:** module layout, resource addresses and variables have all changed. The prototype could not be applied successfully (see *Fixed*), so there is no state to migrate.

### Fixed

- **CloudTrail could not deliver logs.** The trail bucket had no bucket policy granting `cloudtrail.amazonaws.com` `s3:GetBucketAcl` and `s3:PutObject`, so creating the trail failed with `InsufficientS3BucketPolicyException`.
- **SIEM Firehose role was invalid and unusable.** The trust policy version was `"2012=10-17"`. The role had no permissions to write to S3. Firehose had no data source. It targeted the CloudTrail evidence bucket, which mixes SIEM output into audit evidence.
- **"Quota enforcement" raised the limit instead.** `aws_servicequotas_service_quota` submits increase requests. Setting the VPC quota to 10 raised it from the default of 5 ([ADR 0004](docs/adr/0004-quota-monitoring-not-enforcement.md)).
- **Automation role was trusted by EC2, not CI.** Any EC2 instance profile could assume a PowerUser role, and no CI system could.
- **Permission boundary listed `vpc:*`.** That is not an IAM service prefix; VPC actions live under `ec2:`.
- **Compliance mapping cited withdrawn and incorrect control IDs.** It used ISO/IEC 27001:2013 numbering (e.g. A.12.4.1) and TISAX IDs that did not match the VDA ISA catalogue.
- **README described files and features that did not exist**, such as `enterprise_strict.tfvars`, `provider.tf` and "tamper-proof" storage.

### Added

- `kms` module: rotating customer-managed key with a per-service, confused-deputy-safe key policy.
- `monitoring` module: 15 CIS AWS v3.0.0 section 4 metric filters and alarms.
- `guardrails` module: EBS encryption by default, IAM Access Analyzer, IAM password policy.
- `threat_detection` module: GuardDuty with severity-filtered EventBridge routing.
- `quota_monitoring` module: vCPU quota utilisation alarms, including GPU families.
- CloudTrail → CloudWatch Logs integration, S3 access logging, versioning, lifecycle and optional Object Lock.
- GitHub OIDC federation with audience and subject pinning, and wildcard rejection.
- Break-glass: MFA-age condition and an alarm on every use.
- Boundary denies for tampering with CloudTrail, GuardDuty, Config, alarms, log groups and evidence buckets.
- Input validation for emails, prefixes, retention values, OIDC subjects, boundary services and non-disableable alarms.
- `terraform test` suites (27 tests) running against a mocked AWS provider.
- CI: fmt, validate, TFLint, tests, Checkov with SARIF, gitleaks and docs drift, with SHA-pinned actions and Dependabot.
- `examples/minimal` and `examples/complete`.
- Documentation: compliance mapping (CIS / ISO 27001:2022 / NIST CSF 2.0 / VDA ISA), threat model, architecture, five ADRs and three runbooks.

### Changed

- Flattened `modules/core/*` into single-purpose modules composed by the root module.
- `features` is now a typed object with `optional(bool, false)` fields. Omitted flags no longer error, and all optional capabilities default to off.
- All resource names are derived from `name_prefix`, so multiple instances can coexist.
- SNS alerts support multiple recipients (`alert_emails`) and are KMS-encrypted with a scoped topic policy.
- Requires AWS provider 6.x.

### Removed

- The `aws_region` variable, which was unused. The caller's provider decides the region.
- The default alert email. An alarm nobody receives is not a control, so a recipient is now required.
