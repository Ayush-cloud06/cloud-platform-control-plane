# Cost controls

Monthly AWS Budget (80% actual, 100% forecast) and daily Cost Anomaly Detection, with support for reusing an account's existing anomaly monitor. Implements CP-22.

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [aws_budgets_budget.monthly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |
| [aws_ce_anomaly_monitor.services](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ce_anomaly_monitor) | resource |
| [aws_ce_anomaly_subscription.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ce_anomaly_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| anomaly\_threshold\_usd | Minimum total impact in USD for a cost anomaly to trigger a notification. | `number` | `10` | no |
| existing\_anomaly\_monitor\_arn | ARN of an existing DIMENSIONAL/SERVICE cost anomaly monitor to reuse instead of creating one. | `string` | `null` | no |
| monthly\_budget\_limit\_usd | Monthly spend limit in USD. Alerts fire at 80% actual and 100% forecasted. | `number` | `50` | no |
| name\_prefix | Prefix applied to every resource name created by the control plane. | `string` | n/a | yes |
| notification\_emails | Email addresses notified about budget thresholds and cost anomalies. | `list(string)` | n/a | yes |
| tags | Tags applied to all taggable resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| anomaly\_monitor\_arn | ARN of the cost anomaly monitor in use. |
| budget\_name | Name of the monthly cost budget. |
<!-- END_TF_DOCS -->
