# Compliance Mapping and Control Traceability

This document traces every control the control plane implements to:

1. **the code** that implements it,
2. **the automated test** that fails CI if it regresses,
3. **the framework requirements** it supports, and
4. **the evidence** an auditor can collect from a live account.

Frameworks referenced:

| Abbreviation | Framework |
| --- | --- |
| **CIS** | CIS Amazon Web Services Foundations Benchmark **v3.0.0** |
| **ISO** | ISO/IEC 27001:**2022** Annex A (the 2013 numbering such as A.12.4.1 is withdrawn) |
| **CSF** | NIST Cybersecurity Framework **2.0** |
| **ISA** | VDA ISA 6 (TISAX). *Indicative only; confirm against the catalogue version your assessment uses.* |

> **Scope note.** A technical baseline supports these requirements. It does not by itself make an organisation compliant with them. Policies, risk assessment, people processes and evidence of *operating* effectiveness over time are still required. The control IDs below (`CP-xx`) are stable, so an ISMS Statement of Applicability can reference them.

---

## 1. Control matrix

Type: **P** = preventive · **D** = detective · **R** = responsive · **M** = manual (runbook)

### Identity and access

| ID | Control | Type | Implementation | Test (`tests/`) | CIS | ISO | CSF | ISA |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CP-01 | Humans access the account only through roles; no IAM users are created; every human role requires MFA | P | [`modules/iam/roles.tf`](../modules/iam/roles.tf) `aws_iam_role.admin`, `.security_auditor` | `human_roles_require_mfa_and_no_ci_role_by_default` | 1.7 | A.5.15, A.5.16, A.8.5 | PR.AA-01, PR.AA-03 | 4.1.2 |
| CP-02 | Privileged and audit duties are separated into distinct roles with bounded session lengths (1 h admin, 4 h auditor) | P | [`modules/iam/roles.tf`](../modules/iam/roles.tf) | same as above | — | A.5.3, A.8.2 | PR.AA-05 | 4.2.1 |
| CP-03 | Workload automation is capped by a permission boundary: allow-listed services only; IAM, Organizations and account actions denied; security telemetry and audit evidence cannot be disabled or deleted | P | [`modules/iam/permission_boundary.tf`](../modules/iam/permission_boundary.tf) | `human_roles_require_mfa_and_no_ci_role_by_default`, `rejects_iam_in_boundary_allow_list` | — | A.8.2, A.5.15 | PR.AA-05 | 4.2.1 |
| CP-04 | CI/CD authenticates with short-lived GitHub OIDC tokens pinned to audience and repository subject; no long-lived access keys exist; wildcard subjects are rejected | P | [`modules/iam/roles.tf`](../modules/iam/roles.tf) `aws_iam_role.workload_automation` | `github_oidc_role_is_pinned_to_audience_and_subject`, `rejects_wildcard_github_subject` | — | A.5.17, A.8.5 | PR.AA-01, PR.AA-03 | 4.1.2 |
| CP-05 | Emergency (break-glass) access requires named principals and MFA within the last hour, and every use raises an alarm | P, D | [`modules/break_glass/main.tf`](../modules/break_glass/main.tf) | `break_glass_requires_fresh_mfa_and_is_loud` | — | A.8.2, A.5.26 | PR.AA-05, DE.CM-03 | 4.2.1 |
| CP-06 | IAM password policy: 14+ characters, complexity, 24-password reuse prevention (a backstop, since no IAM users are intended) | P | [`modules/guardrails/main.tf`](../modules/guardrails/main.tf) | `account_guardrails_are_secure_by_default` | 1.8, 1.9 | A.5.17 | PR.AA-01 | 4.1.2 |
| CP-07 | IAM Access Analyzer continuously flags resources shared outside the account | D | [`modules/guardrails/main.tf`](../modules/guardrails/main.tf) | same as above | 1.20 | A.5.15, A.8.3 | PR.AA-05, DE.CM-09 | 4.2.1 |
| CP-08 | Root user: MFA on, no access keys, no routine use | M, D | [runbook](runbooks/root-account-hardening.md); root use detected by CP-15 | — | 1.4, 1.5, 1.6, 1.7 | A.8.2, A.8.5 | PR.AA-01 | 4.1.2 |

### Logging and audit evidence

| ID | Control | Type | Implementation | Test | CIS | ISO | CSF | ISA |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CP-09 | A multi-region CloudTrail trail records all management events, including global services | D | [`modules/logging/cloudtrail.tf`](../modules/logging/cloudtrail.tf) | `cloudtrail_is_multi_region_validated_and_encrypted` | 3.1 | A.8.15 | PR.PS-04, DE.CM-03 | 5.2.4 |
| CP-10 | Log integrity: digest-based file validation, bucket versioning, optional S3 Object Lock (WORM) | P, D | [`modules/logging/`](../modules/logging/) | same + `object_lock_can_be_enabled` | 3.2 | A.8.15, A.5.28, A.5.33 | PR.DS-01 | 5.2.4 |
| CP-11 | Audit data is encrypted with a customer-managed KMS key that rotates automatically; the key policy is scoped per service with confused-deputy conditions | P | [`modules/kms/main.tf`](../modules/kms/main.tf) | `kms_key_rotates_and_scopes_cloudtrail` | 3.5, 3.6 | A.8.24 | PR.DS-01 | 5.1.1 |
| CP-12 | Server access logging is enabled on the CloudTrail bucket | D | [`modules/logging/buckets.tf`](../modules/logging/buckets.tf) | `cloudtrail_is_multi_region_validated_and_encrypted` | 3.4 | A.8.15 | PR.PS-04 | 5.2.4 |
| CP-13 | Log buckets deny non-TLS requests and block all public access | P | [`modules/logging/buckets.tf`](../modules/logging/buckets.tf) | same | 2.1.1 | A.8.24, A.8.3 | PR.DS-01, PR.DS-02 | 5.1.2 |
| CP-14 | Retention: 365 days in S3 (Glacier IR after 90), 365 days in CloudWatch Logs; minimums enforced by validation | P | [`variables.tf`](../variables.tf), [`modules/logging/`](../modules/logging/) | `rejects_unsupported_log_retention`, `archive_must_precede_expiry` | — | A.5.33, A.8.10, A.8.15 | PR.PS-04 | 5.2.4 |

### Detection and response

| ID | Control | Type | Implementation | Test | CIS | ISO | CSF | ISA |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CP-15 | Metric filter and alarm for each high-risk activity: unauthorised API calls, console sign-in without MFA, root use, IAM policy changes, CloudTrail changes, console auth failures, CMK disable/deletion, S3 bucket policy changes, Config changes, security groups, NACLs, network gateways, route tables, VPCs, Organizations | D | [`modules/monitoring/main.tf`](../modules/monitoring/main.tf) | `core_only_by_default`, `every_alarm_notifies_the_alert_topic`, `rejects_disabling_root_usage_alarm` | 4.1–4.15 | A.8.16 | DE.CM-03, DE.CM-09, DE.AE-02 | 5.2.4 |
| CP-16 | All security signals route to one KMS-encrypted SNS topic; only this account's alarms and EventBridge rules may publish | R | [`modules/alerting/main.tf`](../modules/alerting/main.tf) | `alert_topic_is_encrypted_and_scoped` | — | A.6.8, A.5.24 | DE.AE-06 | 1.6.1 |
| CP-17 | GuardDuty threat detection; High and Critical findings are routed to the alert topic | D | [`modules/threat_detection/main.tf`](../modules/threat_detection/main.tf) | `guardduty_high_severity_findings_are_routed` | — | A.8.16, A.8.7 | DE.CM-01, DE.CM-09, DE.AE-02 | 5.2.3 |
| CP-18 | CloudTrail events stream to an encrypted SIEM staging bucket through Firehose (separate from the evidence bucket; 30-day minimisation) | D | [`modules/siem/main.tf`](../modules/siem/main.tf) | `siem_pipeline_is_encrypted_and_least_privilege` | — | A.8.15, A.8.16 | DE.AE-03 | 5.2.4 |
| CP-19 | Documented response procedures for each alarm and for break-glass use | M | [`docs/runbooks/`](runbooks/) | — | — | A.5.24, A.5.26 | RS.MA-01 | 1.6.2 |

### Configuration, resilience and change

| ID | Control | Type | Implementation | Test | CIS | ISO | CSF | ISA |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CP-20 | Account-wide S3 Block Public Access | P | [`modules/guardrails/main.tf`](../modules/guardrails/main.tf) | `account_guardrails_are_secure_by_default` | 2.1.4 | A.8.3, A.8.12 | PR.PS-01 | — |
| CP-21 | EBS encryption by default | P | [`modules/guardrails/main.tf`](../modules/guardrails/main.tf) | same | 2.2.1 | A.8.24 | PR.DS-01 | 5.1.1 |
| CP-22 | Monthly budget (80% actual and 100% forecast) and daily cost anomaly detection | D | [`modules/cost_controls/main.tf`](../modules/cost_controls/main.tf) | `cost_controls_reuse_existing_anomaly_monitor` | — | A.8.6 | PR.IR-04 | — |
| CP-23 | EC2 vCPU usage alarms against the live service quota (crypto-mining tripwire) | D | [`modules/quota_monitoring/main.tf`](../modules/quota_monitoring/main.tf) | `quota_alarms_compare_usage_against_service_quota` | — | A.8.6, A.8.16 | PR.IR-04, DE.CM-09 | — |
| CP-24 | All changes are code-reviewed and gated: fmt, validate, TFLint, `terraform test`, Checkov (SARIF to code scanning), gitleaks; actions pinned to commit SHAs; `contents: read` by default | P | [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) | CI itself | — | A.8.9, A.8.25, A.8.29, A.8.32 | PR.PS-01, PR.PS-06 | 5.2.1 |
| CP-25 | Scanner exceptions are recorded inline next to the resource, each with a written justification | M | `#checkov:skip` comments; [`.checkov.yml`](../.checkov.yml) | Checkov | — | A.5.36 | GV.OV-01 | — |

---

## 2. Evidence collection

Run with the `<prefix>-security-auditor` role (read-only, MFA). Each command maps to a control above. Store the output with a timestamp as point-in-time evidence. Store the Git history and CI runs as evidence of *design* and change control.

```bash
P=cp   # your name_prefix

# CP-01/02 Roles require MFA
aws iam get-role --role-name $P-admin --query 'Role.AssumeRolePolicyDocument'
# CP-03 Boundary content
aws iam get-policy-version --policy-arn $(aws iam list-policies --scope Local \
  --query "Policies[?PolicyName=='$P-workload-boundary'].Arn" --output text) --version-id v1
# CP-07 Access Analyzer active, and any open findings
aws accessanalyzer list-analyzers --query 'analyzers[].{name:name,status:status}'
# CP-08 Root hardening
aws iam get-account-summary --query 'SummaryMap.{mfa:AccountMFAEnabled,rootKeys:AccountAccessKeysPresent}'
# CP-09/10/11 Trail status and settings
aws cloudtrail get-trail --name $P-trail
aws cloudtrail get-trail-status --name $P-trail --query '{logging:IsLogging,lastDelivery:LatestDeliveryTime}'
# CP-10 Validate log file integrity for a time window (proves no tampering)
aws cloudtrail validate-logs --trail-arn $(aws cloudtrail get-trail --name $P-trail --query Trail.TrailARN --output text) \
  --start-time $(date -u -d '-1 day' +%Y-%m-%dT%H:%M:%SZ)
# CP-11 Key rotation
aws kms get-key-rotation-status --key-id alias/$P-security-telemetry
# CP-15 Alarms exist, have actions, and are OK
aws cloudwatch describe-alarms --alarm-name-prefix $P- \
  --query 'MetricAlarms[].{name:AlarmName,state:StateValue,actions:length(AlarmActions)}' --output table
# CP-16 Subscriptions are confirmed (not PendingConfirmation)
aws sns list-subscriptions-by-topic --topic-arn $(aws sns list-topics \
  --query "Topics[?ends_with(TopicArn, ':$P-security-alerts')].TopicArn" --output text)
# CP-20/21 Account guardrails
aws s3control get-public-access-block --account-id $(aws sts get-caller-identity --query Account --output text)
aws ec2 get-ebs-encryption-by-default
```

---

## 3. Gap analysis: what this baseline does **not** cover

Knowing the boundary of a control set matters as much as the controls themselves. These CIS v3.0.0 recommendations and adjacent needs are out of scope today:

| Gap | Requirement | Why not yet | Planned approach |
| --- | --- | --- | --- |
| AWS Config recorder in all regions | CIS 3.3 | Per-item recording cost; best deployed org-wide | Org-level Config with a delegated administrator |
| VPC flow logs | CIS 3.7 | The baseline creates no VPCs | Enforce in the network module or with an SCP / Config rule |
| S3 object-level data events | CIS 3.8, 3.9 | Data events can dominate CloudTrail cost | Opt-in `advanced_event_selector` for sensitive buckets |
| Security Hub (CSPM) | CIS 4.16 | Duplicates CP-15 in a single account; valuable org-wide | Delegated admin with CIS v3.0.0 standard enabled |
| AWS Support role for incident management | CIS 1.17 | Needs a named incident team first | Role with `AWSSupportAccess` bound to the IR group |
| Preventive guardrails (region deny, leave-org deny) | — | SCPs require AWS Organizations | SCP module in the org management account |
| Organisation trail and central log archive account | — | Single-account scope | Org trail to a dedicated log archive account |
| Automated remediation | — | Detection first, then trusted auto-response | EventBridge → Lambda/SSM for high-confidence cases (e.g. re-enable trail) |
