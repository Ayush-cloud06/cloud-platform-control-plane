# Alerting

KMS-encrypted SNS topic that every control plane signal fans out through. The topic policy only admits this account's CloudWatch alarms and EventBridge rules. Implements CP-16.

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [aws_sns_topic.security_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.security_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alert\_emails | Email addresses subscribed to the security alert topic. | `list(string)` | n/a | yes |
| kms\_key\_arn | ARN of the KMS key used to encrypt the SNS topic. | `string` | n/a | yes |
| name\_prefix | Prefix applied to every resource name created by the control plane. | `string` | n/a | yes |
| tags | Tags applied to all taggable resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| topic\_arn | ARN of the security alert SNS topic. |
| topic\_name | Name of the security alert SNS topic. |
<!-- END_TF_DOCS -->
