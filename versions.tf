/*
Refactor Note:

This repository is designed to function as a reusable, provider-agnostic
landing zone module.

The previous standalone provider configuration (provider.tf) was removed
intentionally to allow the parent/root module to inject the appropriate
AWS provider configuration (e.g., via assume_role for multi-account setups).

This enables:
- Multi-account deployments (security, dev, prod, etc.)
- Provider alias injection from consuming projects
- Proper separation between platform module and environment orchestration

This repository is no longer intended to be executed directly as a
standalone Terraform root. It is consumed by a higher-level landing zone
orchestrator.
*/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
