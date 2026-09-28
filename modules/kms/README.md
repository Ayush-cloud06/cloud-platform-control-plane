# KMS

Customer-managed key for all security telemetry (CloudTrail, CloudWatch Logs, SNS, SIEM). Automatic yearly rotation; key policy scoped per service with `aws:SourceArn` confused-deputy protection. Implements CP-11 (CIS 3.5, 3.6). See [ADR 0005](../../docs/adr/0005-single-cmk-for-security-telemetry.md).

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudtrail\_name | Name of the CloudTrail trail allowed to encrypt with this key. Used to scope the key policy with aws:SourceArn. | `string` | n/a | yes |
| deletion\_window\_in\_days | Waiting period before the key is destroyed after deletion is scheduled. | `number` | `30` | no |
| name\_prefix | Prefix applied to every resource name created by the control plane. | `string` | n/a | yes |
| tags | Tags applied to all taggable resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alias\_name | Alias of the security telemetry KMS key. |
| key\_arn | ARN of the security telemetry KMS key. |
| key\_id | ID of the security telemetry KMS key. |
<!-- END_TF_DOCS -->
