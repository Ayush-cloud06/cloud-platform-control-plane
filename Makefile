.DEFAULT_GOAL := help
.PHONY: help init fmt validate lint test scan docs ci

EXAMPLES := examples/minimal examples/complete

help: ## Show available targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-10s %s\n", $$1, $$2}'

init: ## Initialise the module and examples (no backend)
	terraform init -backend=false -input=false
	@for d in $(EXAMPLES); do terraform -chdir=$$d init -backend=false -input=false; done

fmt: ## Format all Terraform files
	terraform fmt -recursive

validate: init ## Check formatting and validate module and examples
	terraform fmt -check -recursive
	terraform validate
	@for d in $(EXAMPLES); do terraform -chdir=$$d validate; done

lint: ## Run TFLint across all modules
	tflint --init
	tflint --recursive --format compact

test: init ## Run terraform test against the mocked AWS provider (no credentials needed)
	terraform test

scan: ## Run Checkov IaC security scan
	checkov --config-file .checkov.yml -d .

docs: ## Regenerate the terraform-docs sections of every README
	terraform-docs .
	@for m in modules/*/; do terraform-docs -c modules/.terraform-docs.yml $$m; done

ci: validate lint test scan ## Run every CI gate locally
