# ADR 0002: CloudTrail metric filters over EventBridge rules for API activity

**Status:** Accepted

## Context

The control plane must alert on high-risk API activity: root usage, IAM policy changes, CloudTrail tampering, console sign-in without MFA, and the rest of CIS AWS Foundations v3.0.0 section 4.

There are two common ways to do this:

1. **EventBridge rules** matching `AWS API Call via CloudTrail` events.
2. **CloudWatch Logs metric filters** on the log group the trail delivers to, each with an alarm.

EventBridge looks more modern, but it has a regional blind spot. Events from *global* services (IAM, STS console sign-in, Organizations) are delivered to EventBridge **only in us-east-1**. A rule deployed in `eu-central-1` or `ap-south-1` would never see `AttachRolePolicy` or a root `ConsoleLogin`, and it would fail without any error.

## Decision

- The multi-region trail (with `include_global_service_events = true`) delivers every event from every region into **one** CloudWatch log group in the home region.
- Each detection is a metric filter with an alarm on that log group, publishing to the KMS-encrypted alert topic.
- Detections are data: a `locals` map of `key → {cis, description, pattern, threshold}`, so adding a detection is a one-entry change. Alarms that suit only some accounts (e.g. `organizations-changes`) can be disabled per account. The two that must never be disabled (root usage and CloudTrail changes) are enforced by variable validation.
- **Exception:** GuardDuty findings *are* regional and are emitted to EventBridge in the region that produced them. `threat_detection` therefore correctly uses an EventBridge rule.

## Consequences

- One deployment in any region gets full coverage, with no us-east-1 side deployment to keep in sync.
- The cost is CloudWatch Logs ingestion (roughly USD 0.50–0.70 per GB) plus USD 0.10 per alarm per month. For management events in a typical account this is a few dollars a month.
- Latency is minutes, not seconds (log delivery plus a 5-minute alarm period). That is acceptable for these detective controls. Anything that needs sub-minute response belongs in automated remediation, which is on the roadmap.
