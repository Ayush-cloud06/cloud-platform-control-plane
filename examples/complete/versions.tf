terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }

  # Keep state remote, encrypted and locked for anything beyond a sandbox:
  # backend "s3" {
  #   bucket       = "<state-bucket>"
  #   key          = "control-plane/terraform.tfstate"
  #   region       = "eu-central-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}
