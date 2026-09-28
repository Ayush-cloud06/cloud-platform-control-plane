# Threat detection

Amazon GuardDuty detector, with findings at or above a severity threshold routed to the alert topic via EventBridge. Implements CP-17.

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.guardduty_findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.guardduty_to_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_guardduty_detector.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alarm\_topic\_arn | SNS topic receiving GuardDuty findings. | `string` | n/a | yes |
| finding\_publishing\_frequency | How often updated findings are exported: FIFTEEN\_MINUTES, ONE\_HOUR or SIX\_HOURS. | `string` | `"FIFTEEN_MINUTES"` | no |
| min\_severity | Minimum GuardDuty severity routed to the alert topic (Low 1-3.9, Medium 4-6.9, High 7-8.9, Critical 9-10). | `number` | `7` | no |
| name\_prefix | Prefix applied to every resource name created by the control plane. | `string` | n/a | yes |
| tags | Tags applied to all taggable resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| detector\_id | ID of the GuardDuty detector. |
| event\_rule\_arn | ARN of the EventBridge rule routing GuardDuty findings. |
<!-- END_TF_DOCS -->
