# ADR 0005: One customer-managed KMS key for security telemetry

**Status:** Accepted

## Context

CloudTrail files, the CloudTrail log group, the alert topic and the SIEM pipeline all need encryption at rest. CIS AWS 3.5 specifically requires CloudTrail to use a customer-managed key (SSE-KMS) rather than SSE-S3, because a CMK adds a *second* authorisation layer: reading a log file needs both `s3:GetObject` and `kms:Decrypt`. The key policy also becomes the place to audit and revoke access to audit data.

The options were one key per service, or one key for the whole "security telemetry" data class.

## Decision

- **One** CMK, `alias/<prefix>-security-telemetry`, with automatic annual rotation (CIS 3.6) and a 30-day deletion window.
- The key policy grants each AWS service only what it needs, scoped with conditions:
  - CloudTrail: `GenerateDataKey*` only for this account's trails, plus an `aws:SourceArn` match on *this* trail (confused-deputy protection).
  - CloudWatch Logs: only for log groups in this account and region, via the `aws:logs:arn` encryption context.
  - CloudWatch alarms and EventBridge: `Decrypt` and `GenerateDataKey*` to publish to the encrypted topic. *Who* may publish is controlled by the topic policy, which restricts `aws:SourceArn` to this account's alarms and rules.
- Human and role access is delegated to IAM (`EnableIAMPolicies`). No wildcard principals.
- Disabling or scheduling deletion of any CMK raises the `kms-key-disable-or-deletion` alarm (CIS 4.7). The workload boundary denies `kms:*` implicitly, because KMS is not on its allow list.

## Consequences

- USD 1 per month for the key instead of USD 4 or more, and one key policy to review instead of four.
- The blast radius is shared: disabling this key blinds CloudTrail delivery, alerting and SIEM export at once. That is why key disablement is itself a monitored, alarmed event.
- Organisations that need separate keys per data owner can split them later without changing module interfaces, since every module takes `kms_key_arn` as an input.
