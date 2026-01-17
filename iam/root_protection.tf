# Root accout protection :
# - MFA must be enabled manually
# - Root access keys must be deleted manually
#
# Terraform cannot enforce these automatically, so this file defines
# the baseline expectation and document the security posture

data "aws_caller_identity" "current" {}

output "root_account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS Account ID. Root user must be protected with MFA and no access keys."
}
