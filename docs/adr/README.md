# Architecture Decision Records

Each record captures one significant decision: the context, what was decided, and what it costs. They are immutable once accepted; a reversal is a new ADR that supersedes the old one.

| ADR | Decision | Status |
| --- | --- | --- |
| [0001](0001-reusable-module-with-examples.md) | Ship as a reusable module with runnable examples, not a root configuration | Accepted |
| [0002](0002-metric-filters-over-eventbridge.md) | Detect API activity with CloudTrail metric filters, not EventBridge rules | Accepted |
| [0003](0003-github-oidc-for-ci.md) | Federate CI through GitHub OIDC; never issue access keys | Accepted |
| [0004](0004-quota-monitoring-not-enforcement.md) | Monitor service quotas as a tripwire instead of "enforcing" them | Accepted |
| [0005](0005-single-cmk-for-security-telemetry.md) | One customer-managed KMS key for all security telemetry | Accepted |
