# Break glass

Emergency administrator role restricted to named principals with MFA in the last hour, plus an alarm on every API call made with it. Implements CP-05. Procedure: [break-glass runbook](../../docs/runbooks/break-glass.md).

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_metric_filter.break_glass_used](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_metric_alarm.break_glass_used](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_iam_role.break_glass](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.break_glass](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alarm\_topic\_arn | SNS topic notified when the break-glass role is used. | `string` | n/a | yes |
| log\_group\_name | CloudWatch log group receiving CloudTrail events, used to detect break-glass use. | `string` | n/a | yes |
| max\_mfa\_age\_seconds | The caller must have authenticated with MFA within this many seconds. | `number` | `3600` | no |
| max\_session\_duration | Maximum break-glass session duration in seconds. | `number` | `3600` | no |
| metric\_namespace | CloudWatch namespace for the break-glass usage metric. | `string` | `"ControlPlane/Security"` | no |
| name\_prefix | Prefix applied to every resource name created by the control plane. | `string` | n/a | yes |
| tags | Tags applied to all taggable resources. | `map(string)` | `{}` | no |
| trusted\_principal\_arns | Principals allowed to assume the break-glass role. Empty means any principal in this account allowed by its own IAM policy; name specific principals in production. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| alarm\_arn | ARN of the alarm raised whenever the break-glass role is used. |
| role\_arn | ARN of the break-glass role. |
<!-- END_TF_DOCS -->
