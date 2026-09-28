# Logging

Multi-region CloudTrail with log file validation, delivered to an SSE-KMS, versioned, access-logged S3 bucket with lifecycle and optional S3 Object Lock, and to a CloudWatch log group that powers detection and SIEM export. Implements CP-09 to CP-14 (CIS 2.1.1, 3.1, 3.2, 3.4, 3.5).

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_log_group.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.cloudtrail_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cloudtrail_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_object_lock_configuration.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration) | resource |
| [aws_s3_bucket_ownership_controls.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.trail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudwatch\_log\_retention\_days | Retention of the CloudTrail CloudWatch log group. Must be a value CloudWatch Logs accepts. | `number` | `365` | no |
| force\_destroy | Allow Terraform to delete non-empty log buckets. Only for disposable sandbox accounts. | `bool` | `false` | no |
| kms\_key\_arn | ARN of the KMS key used to encrypt CloudTrail files, the trail bucket and the log group. | `string` | n/a | yes |
| log\_archive\_after\_days | Days after which CloudTrail files transition to S3 Glacier Instant Retrieval. | `number` | `90` | no |
| log\_retention\_days | Days CloudTrail files and S3 access logs are retained in S3 before expiry. | `number` | `365` | no |
| name\_prefix | Prefix applied to every resource name created by the control plane. | `string` | n/a | yes |
| object\_lock\_mode | S3 Object Lock mode: GOVERNANCE (bypassable with s3:BypassGovernanceRetention) or COMPLIANCE (irreversible). | `string` | `"GOVERNANCE"` | no |
| object\_lock\_retention\_days | Default S3 Object Lock retention for CloudTrail files. 0 disables Object Lock. Can only be enabled when the bucket is first created. | `number` | `0` | no |
| tags | Tags applied to all taggable resources. | `map(string)` | `{}` | no |
| trail\_name | Name of the CloudTrail trail. Must match the name the KMS key policy is scoped to. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| access\_log\_bucket\_arn | ARN of the S3 server access log bucket. |
| access\_log\_bucket\_name | Name of the S3 server access log bucket. |
| log\_group\_arn | ARN of the CloudWatch log group receiving CloudTrail events. |
| log\_group\_name | Name of the CloudWatch log group receiving CloudTrail events. |
| trail\_arn | ARN of the CloudTrail trail. |
| trail\_bucket\_arn | ARN of the S3 bucket holding CloudTrail files. |
| trail\_bucket\_name | Name of the S3 bucket holding CloudTrail files. |
| trail\_name | Name of the CloudTrail trail. |
<!-- END_TF_DOCS -->
