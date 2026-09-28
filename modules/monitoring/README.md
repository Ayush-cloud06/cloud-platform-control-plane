# Monitoring

CloudWatch Logs metric filters and alarms for CIS AWS Foundations v3.0.0 section 4 (4.1-4.15). Detections are defined as data in `locals.alarms`. Implements CP-15. See [ADR 0002](../../docs/adr/0002-metric-filters-over-eventbridge.md) for why this uses metric filters rather than EventBridge.

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_metric_filter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_metric_alarm.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alarm\_topic\_arn | SNS topic that alarms notify. | `string` | n/a | yes |
| disabled\_alarms | Alarm keys to skip (e.g. ["organizations-changes"] in an account that is not an Organizations management account). | `list(string)` | `[]` | no |
| log\_group\_name | CloudWatch log group receiving the multi-region CloudTrail events. | `string` | n/a | yes |
| metric\_namespace | CloudWatch namespace for the security metrics. | `string` | `"ControlPlane/Security"` | no |
| name\_prefix | Prefix applied to every resource name created by the control plane. | `string` | n/a | yes |
| tags | Tags applied to all taggable resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alarm\_arns | Map of alarm key to CloudWatch alarm ARN. |
| alarm\_cis\_controls | Map of alarm key to the CIS AWS Foundations v3.0.0 recommendation it implements. |
| available\_alarms | Every alarm key this module knows about, for use with disabled\_alarms. |
<!-- END_TF_DOCS -->
