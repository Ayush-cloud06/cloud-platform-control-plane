# Threat Model

**Scope:** a single AWS account governed by this control plane.
**Method:** attacker goals first, then the controls that prevent, detect or limit each one, then what is left over. Control IDs refer to [compliance-mapping.md](compliance-mapping.md).

## Assets

| Asset | Why it matters |
| --- | --- |
| Account control (IAM, root) | Whoever holds it holds everything else |
| Audit evidence (CloudTrail files, log group) | Needed for incident reconstruction, legal hold and certification audits |
| Detective controls (alarms, GuardDuty, alert topic) | Silencing them is how an intrusion stays unnoticed |
| Workload data and compute | Business impact, regulatory exposure, cost |

## Trust boundaries

1. **Human → AWS:** people authenticate through an IdP or IAM principal, then assume MFA-gated roles.
2. **CI → AWS:** GitHub Actions exchanges an OIDC token for 1-hour STS credentials.
3. **AWS services → control plane:** CloudTrail, CloudWatch, EventBridge and Firehose act through resource and key policies scoped with `aws:SourceArn` / `aws:SourceAccount`.
4. **Control plane → people:** SNS email delivery.

## Threats and controls

| # | Threat (attacker goal) | Example technique (MITRE ATT&CK) | Prevent | Detect | Residual risk |
| --- | --- | --- | --- | --- | --- |
| T1 | Take over the account through the root user | Valid accounts: cloud (T1078.004) | Root MFA, no root keys (CP-08) | `root-account-usage` alarm (CP-15) | Root credential recovery via email; protect the root mailbox |
| T2 | Steal long-lived CI credentials | Unsecured credentials (T1552) | No access keys exist; OIDC tokens are short-lived and bound to a repository and environment (CP-04) | `unauthorized-api-calls` burst alarm | A compromised workflow in the *trusted* repository can still assume the role; mitigate with GitHub environment protection rules |
| T3 | Escalate from workload automation to admin | Account manipulation (T1098) | Boundary denies all `iam:*`, `sts:AssumeRole`, `organizations:*` (CP-03) | `iam-policy-changes` alarm | Service-specific escalation paths inside allow-listed services (e.g. EC2 user data on an instance with a privileged profile) |
| T4 | Blind the defenders | Impair defenses: disable cloud logs (T1562.008) | Boundary denies stopping, deleting or updating CloudTrail, GuardDuty, Config, alarms, log group filters and retention (CP-03) | `cloudtrail-config-changes`, `config-changes`, `kms-key-disable-or-deletion` alarms (CP-15) | An *admin* can still do this. That is by design, and the action itself is alarmed |
| T5 | Destroy or alter audit evidence | Indicator removal (T1070) | Versioning, optional Object Lock, boundary denies object deletion and bucket policy changes (CP-10, CP-03) | Log file validation proves tampering (CP-10); `s3-bucket-policy-changes` alarm | GOVERNANCE-mode lock can be bypassed by a privileged principal; use COMPLIANCE mode for regulated accounts |
| T6 | Read audit data to learn the environment | Data from cloud storage (T1530) | SSE-KMS with a CMK: reading needs `s3:GetObject` **and** `kms:Decrypt` (CP-11); public access blocked (CP-13, CP-20) | CloudTrail records KMS `Decrypt` calls | Admins can read logs; separating the log archive account removes this |
| T7 | Expose data publicly | Transfer data to cloud account (T1537) | Account-level S3 Block Public Access (CP-20) | IAM Access Analyzer (CP-07); `s3-bucket-policy-changes` alarm | Cross-account grants to attacker-owned accounts are *flagged*, not blocked |
| T8 | Mine crypto with stolen credentials | Resource hijacking (T1496) | Boundary limits services (CP-03) | vCPU quota tripwire including GPU classes (CP-23), cost anomaly detection (CP-22), GuardDuty `CryptoCurrency:*` findings (CP-17) | Detection latency of minutes to hours; SCPs denying unused regions and instance families would prevent it |
| T9 | Open network paths for exfiltration or command and control | Modify cloud compute infrastructure (T1578) | — | Security group, NACL, gateway, route and VPC change alarms (CP-15) | Detective only |
| T10 | Abuse break-glass access | Valid accounts (T1078) | Named principals, fresh MFA, 1-hour sessions (CP-05) | Alarm on *every* API call made with the role (CP-05) | Collusion between the principal holder and the reviewer |
| T11 | Suppress alerts | Impair defenses (T1562) | Topic policy scoped to this account's alarms and rules; boundary denies alarm deletion and state changes (CP-16, CP-03) | Unconfirmed SNS subscriptions are visible in evidence collection | Email is a single channel; add a paging integration (PagerDuty or Opsgenie via HTTPS subscription) |
| T12 | Push a malicious change through the pipeline | Supply chain compromise (T1195) | Actions pinned to commit SHAs, `contents: read` token, Dependabot, code review (CP-24) | Checkov and gitleaks in CI; `iam-policy-changes` alarm on apply | Requires branch protection with required reviews to be configured on the repository |

## Accepted risks

- **Single account.** Admins of the account can, in principle, undo any control. Every such action is recorded and alarmed, but true separation needs a multi-account organisation with a dedicated log archive account and SCPs. See the gap analysis in [compliance-mapping.md](compliance-mapping.md#3-gap-analysis-what-this-baseline-does-not-cover).
- **Detective latency.** Metric-filter alarms fire minutes after an event. That suits the response model here; automated remediation is on the roadmap.
