# ADR 0001: Reusable module with runnable examples

**Status:** Accepted

## Context

The first version mixed two roles. It had a root-style `main.tf` and a README telling users to `terraform apply` it directly, yet no provider block (it had been removed so a parent could inject one). It couldn't be used cleanly either way:

- A direct `apply` depended on ambient provider configuration and ignored the `aws_region` variable it declared.
- A parent module couldn't configure it properly: the `environment` variable was required but unused, and hard-coded values (`vpc_quota = 10`, `monthly_budget_limit = 20`) were buried in `main.tf`.

In a multi-account landing zone, the same baseline runs once per account (security, log archive, dev, prod). Each run uses a different `assume_role` and different `default_tags`. Only the caller knows those.

## Decision

- The repository root is a **module**. It declares `required_providers` but no `provider` block.
- Runnable entry points live in `examples/`. `minimal` deploys the core baseline and `complete` deploys every capability. Each owns its provider, backend and tags.
- Every tunable value is a validated root variable. Nothing environment-specific is hard-coded.
- Optional capabilities are toggled through a typed `features` object whose fields use `optional(bool, false)`. A caller who sets only `{ break_glass = true }` gets a valid configuration. With the old `map(bool)`, any missing key caused an error at plan time.

## Consequences

- Consumers pin a version with `source = "git::https://...?ref=vX.Y.Z"` and upgrade deliberately.
- The examples double as executable documentation and are validated in CI.
- Consumers own provider versions, so the module does not commit a `.terraform.lock.hcl`.
