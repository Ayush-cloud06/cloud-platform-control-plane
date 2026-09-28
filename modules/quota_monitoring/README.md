# Quota monitoring

Alarms when EC2 vCPU usage, including GPU families, passes a percentage of the live service quota: a crypto-mining tripwire. Implements CP-23. See [ADR 0004](../../docs/adr/0004-quota-monitoring-not-enforcement.md) for why this monitors rather than enforces.

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.vcpu_quota_utilization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alarm\_topic\_arn | SNS topic notified when quota utilization crosses the threshold. | `string` | n/a | yes |
| name\_prefix | Prefix applied to every resource name created by the control plane. | `string` | n/a | yes |
| tags | Tags applied to all taggable resources. | `map(string)` | `{}` | no |
| utilization\_threshold\_percent | Alarm when usage exceeds this percentage of the quota. | `number` | `80` | no |
| vcpu\_classes | EC2 vCPU usage classes to watch (AWS/Usage 'Class' dimension). G and P are GPU families favoured for crypto-mining. | `list(string)` | <pre>[<br/>  "Standard/OnDemand",<br/>  "G/OnDemand",<br/>  "P/OnDemand"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| alarm\_arns | Map of vCPU class to CloudWatch alarm ARN. |
<!-- END_TF_DOCS -->
