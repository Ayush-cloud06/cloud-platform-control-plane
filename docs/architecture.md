# Architecture

## Layers

The control plane has two layers:

- **Core baseline (always on):** `kms`, `logging`, `alerting`, `monitoring`, `iam`, `guardrails`. An account without these is not a governed account, so they cannot be switched off.
- **Optional capabilities (feature flags):** `break_glass`, `siem`, `cost_controls`, `quota_monitoring`, `threat_detection`.

### Access paths (identity)

```mermaid
flowchart LR
    ENG[Engineers<br/>IdP or IAM principal]
    GH[GitHub Actions workflow]
    EMG[Named emergency<br/>principals]

    ADM[admin role<br/>MFA required · 1 h]
    AUD[security-auditor role<br/>MFA required · 4 h]
    WA[workload-automation role<br/>OIDC · aud + sub pinned · 1 h]
    BG[break-glass role<br/>MFA in last hour · 1 h]
    PB[[workload permission boundary<br/>no IAM · no log tampering]]
    ALARM((alarm on<br/>every use))

    ENG -->|sts:AssumeRole| ADM
    ENG -->|sts:AssumeRole| AUD
    GH -->|AssumeRoleWithWebIdentity| WA
    EMG -->|sts:AssumeRole| BG
    PB -.->|caps| WA
    BG -.-> ALARM
```

### Telemetry, detection and alerting

```mermaid
flowchart LR
    API[API calls in<br/>every region]
    CT[CloudTrail<br/>multi-region trail]
    S3T[(Trail bucket<br/>SSE-KMS · versioned<br/>optional Object Lock)]
    S3A[(Access log<br/>bucket)]
    CWL[CloudWatch<br/>log group]
    MF[16 metric filters<br/>CIS 4.1-4.15 + break-glass]
    AL[CloudWatch<br/>alarms]
    GD[GuardDuty]
    EB[EventBridge rule<br/>severity >= 7]
    Q[vCPU quota<br/>alarms]
    SNS[SNS security-alerts<br/>KMS-encrypted]
    OC[On-call]
    FH[Firehose]
    S3S[(SIEM staging<br/>bucket)]
    SIEM[SIEM]

    API --> CT
    CT --> S3T
    S3T -.->|access logs| S3A
    CT --> CWL
    CWL --> MF --> AL --> SNS
    GD --> EB --> SNS
    Q --> SNS
    SNS --> OC
    CWL -->|subscription filter| FH --> S3S --> SIEM
```

All data at rest in this flow (trail files, log group, topic, Firehose, SIEM bucket) is encrypted with one customer-managed KMS key that rotates every year ([ADR 0005](adr/0005-single-cmk-for-security-telemetry.md)). Budgets and Cost Anomaly Detection email the same recipients directly.

## Event flow for a single detection

Example: someone runs `aws iam attach-role-policy` from any region.

1. IAM is a global service. CloudTrail records the call and, because `include_global_service_events = true`, the multi-region trail delivers it.
2. The event is written (a) as an encrypted, digest-validated file in the trail bucket and (b) to the CloudWatch log group.
3. The `iam-policy-changes` metric filter matches and emits `1` to `ControlPlane/Security`.
4. The alarm evaluates a 5-minute `Sum ≥ 1` and moves to `ALARM`.
5. CloudWatch publishes to the KMS-encrypted SNS topic. The topic policy admits it because `aws:SourceArn` is an alarm in this account and region.
6. On-call receives the email and follows [security-alarm-response.md](runbooks/security-alarm-response.md).
7. If SIEM export is enabled, the same event also reaches the SIEM staging bucket through Firehose for correlation.

## Module dependency graph

```mermaid
flowchart LR
    kms --> logging
    kms --> alerting
    logging --> monitoring
    alerting --> monitoring
    logging --> iam
    logging --> break_glass
    alerting --> break_glass
    logging --> siem
    kms --> siem
    siem -. protected bucket .-> iam
    alerting --> quota_monitoring
    alerting --> threat_detection
    guardrails
    cost_controls
```

## Naming

Every resource name starts with `name_prefix` (default `cp`). Bucket names add account ID and region (`<prefix>-cloudtrail-<account>-<region>`) so they are globally unique and predictable. That is why `name_prefix` is limited to 20 characters: the longest bucket name must fit the 63-character S3 limit.

## Design decisions

The reasoning behind the non-obvious choices is in [ADRs](adr/README.md).
