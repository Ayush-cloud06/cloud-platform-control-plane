# ADR 0004: Quota monitoring as a tripwire, not quota "enforcement"

**Status:** Accepted (supersedes the original `quotas` module)

## Context

The original `quotas` module used `aws_servicequotas_service_quota` to set the VPC quota to 10, described as enforcing a limit "to prevent Shadow IT or cost runaway".

Service Quotas can't do that. `aws_servicequotas_service_quota` submits a quota **increase request**. The VPC default is 5, so the module *raised* the limit. AWS does not let customers lower an applied quota below its default, so the control was cosmetic at best and counterproductive at worst. A compliance mapping that cited it as a preventive control would not survive an auditor's walkthrough.

## Decision

- Replace it with `quota_monitoring`. For each EC2 vCPU class, a CloudWatch alarm fires when usage passes a threshold percentage of the **live** quota: `(usage / SERVICE_QUOTA(usage)) * 100` over `AWS/Usage` metrics.
- By default it watches `Standard/OnDemand`, `G/OnDemand` and `P/OnDemand`. Sudden growth in vCPUs, and in GPU families especially, is the classic footprint of stolen credentials being used for crypto-mining. That makes this a real *detective* security control, not just FinOps.
- Classify it honestly as **detective** in the compliance mapping.

## Consequences

- Real *preventive* limits (deny regions, deny instance families, deny leaving the organisation) belong in **Service Control Policies** at the AWS Organizations level. That is outside a single-account baseline and is on the roadmap.
- If an account's quota for a class is 0, `SERVICE_QUOTA` returns 0 and the expression yields no data. The alarm treats missing data as not breaching, which is correct: nothing of that class can be launched anyway.
