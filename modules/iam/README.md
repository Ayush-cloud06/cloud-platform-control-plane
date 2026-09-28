# IAM

MFA-gated admin and security-auditor roles, an optional GitHub OIDC workload automation role, and the workload permission boundary that denies IAM and any tampering with security telemetry. Implements CP-01 to CP-04. See [ADR 0003](../../docs/adr/0003-github-oidc-for-ci.md).

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.workload_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.security_auditor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.workload_automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.security_auditor_evidence](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.security_auditor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.workload_automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_max\_session\_duration | Maximum session duration in seconds for the admin role. | `number` | `3600` | no |
| auditor\_max\_session\_duration | Maximum session duration in seconds for the security-auditor role. | `number` | `14400` | no |
| boundary\_allowed\_services | IAM service prefixes workload automation may use (subject to the boundary's explicit denies). | `list(string)` | n/a | yes |
| github\_oidc | GitHub Actions OIDC federation for the workload automation role. subjects are matched against the token's sub claim with StringLike. | <pre>object({<br/>    enabled         = optional(bool, false)<br/>    create_provider = optional(bool, true)<br/>    subjects        = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| kms\_key\_arn | KMS key encrypting audit evidence; the security auditor may decrypt with it through S3 only. | `string` | n/a | yes |
| name\_prefix | Prefix applied to every resource name created by the control plane. | `string` | n/a | yes |
| protected\_bucket\_arns | S3 bucket ARNs holding audit evidence that workload automation must never modify. | `list(string)` | n/a | yes |
| protected\_log\_group\_arn | ARN of the CloudTrail log group whose filters and retention workload automation must never modify. | `string` | n/a | yes |
| tags | Tags applied to all taggable resources. | `map(string)` | `{}` | no |
| trusted\_principal\_arns | Principals allowed to assume the admin and security-auditor roles (with MFA). Empty means any principal in this account that is allowed by its own IAM policy. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| admin\_role\_arn | ARN of the MFA-protected admin role. |
| github\_oidc\_provider\_arn | ARN of the GitHub OIDC identity provider, or null when OIDC is disabled. |
| security\_auditor\_role\_arn | ARN of the MFA-protected security auditor role. |
| workload\_automation\_role\_arn | ARN of the GitHub OIDC workload automation role, or null when OIDC is disabled. |
| workload\_boundary\_policy\_arn | ARN of the workload permission boundary. Attach it to any role created for workloads. |
<!-- END_TF_DOCS -->
