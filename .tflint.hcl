config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "all"
}

plugin "aws" {
  enabled = true
  version = "0.38.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Every module intentionally shares one versions.tf and receives tags from the
# root, so a standard module structure is enforced; this rule would demand
# empty main.tf files in modules split by concern (e.g. logging/buckets.tf).
rule "terraform_standard_module_structure" {
  enabled = false
}
