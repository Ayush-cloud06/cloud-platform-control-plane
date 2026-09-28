# ADR 0003: GitHub OIDC federation for CI; no access keys

**Status:** Accepted

## Context

The original "automation role" had a trust policy for `ec2.amazonaws.com`. It was described as the role Terraform and CI would use, but no CI system can assume it. Any EC2 instance given a matching instance profile could, which silently widens who holds PowerUser rights.

The usual workaround, an IAM user with static access keys stored as a CI secret, is the most common root cause of AWS account compromise. Leaked keys stay valid until someone notices.

## Decision

- The workload automation role trusts **only** the GitHub Actions OIDC provider (`token.actions.githubusercontent.com`).
- The trust policy pins the `aud` claim to `sts.amazonaws.com` and the `sub` claim to explicit subjects, e.g. `repo:org/repo:environment:production`.
- Variable validation rejects subjects with wildcards in the owner or repository segment. A trust like `repo:*` would let *any* GitHub repository assume the role, a real misconfiguration that has been exploited in the wild.
- Credentials are short-lived (at most 1 hour) and scoped per workflow run. No secret exists to leak.
- The role is created only when `github_oidc.enabled = true`. Without it the account has no CI role at all.
- The account can have only one GitHub OIDC provider, so `create_provider = false` reuses an existing one.

## Consequences

- The workload role is capped by the workload permission boundary, which **denies all IAM actions**. That is deliberate: a pipeline that deploys workloads must not be able to change who can do what. The flip side is that this role **cannot deploy the control plane itself**. That needs a separate, more tightly held deployer role, created during account bootstrap.
- Workloads that need `iam:PassRole` (e.g. EC2 instance profiles) require a scoped exception in the boundary. This is a conscious trade-off in favour of a simple, auditable default.
