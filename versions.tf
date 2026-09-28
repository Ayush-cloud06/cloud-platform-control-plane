# This repository is a reusable module: it deliberately declares no provider
# block, so the caller controls region, credentials, assume_role and
# default_tags (e.g. one instance per account in a multi-account setup).
# Runnable entry points live in examples/. See docs/adr/0001-reusable-module-with-examples.md.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Used only through child modules; declared here so callers see and
    # resolve a single provider version constraint.
    # tflint-ignore: terraform_unused_required_providers
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}
