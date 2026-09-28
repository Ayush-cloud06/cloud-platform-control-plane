# SIEM export

CloudTrail log group, then subscription filter, then Kinesis Data Firehose (CMK-encrypted), then a dedicated, encrypted, expiring S3 staging bucket for a SIEM to ingest from. Implements CP-18.

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_subscription_filter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_iam_role.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.logs_to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.logs_to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kinesis_firehose_delivery_stream.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream) | resource |
| [aws_s3_bucket.staging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.staging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.staging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.staging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.staging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.staging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.staging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.staging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_log\_bucket\_name | Bucket receiving S3 server access logs for the staging bucket. | `string` | n/a | yes |
| filter\_pattern | CloudWatch Logs filter pattern selecting which events are exported. Empty string exports everything. | `string` | `""` | no |
| force\_destroy | Allow Terraform to delete the staging bucket when it still contains objects. | `bool` | `false` | no |
| kms\_key\_arn | KMS key used to encrypt the Firehose stream and staging bucket. | `string` | n/a | yes |
| name\_prefix | Prefix applied to every resource name created by the control plane. | `string` | n/a | yes |
| retention\_days | Days SIEM export objects are kept in the staging bucket. The SIEM is the system of record for this data. | `number` | `30` | no |
| source\_log\_group\_name | CloudWatch log group to stream to the SIEM (the CloudTrail log group). | `string` | n/a | yes |
| tags | Tags applied to all taggable resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| delivery\_stream\_arn | ARN of the Firehose delivery stream. |
| staging\_bucket\_arn | ARN of the S3 bucket the SIEM ingests from. |
| staging\_bucket\_name | Name of the S3 bucket the SIEM ingests from. |
<!-- END_TF_DOCS -->
