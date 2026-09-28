# Security Policy

## Reporting a vulnerability

If you find a security weakness in this module, such as a control that does not do what the documentation claims, an over-broad policy, or a bypass of the permission boundary, please **do not open a public issue**.

Report it privately through [GitHub private vulnerability reporting](https://github.com/Ayush-cloud06/cloud-platform-control-plane/security/advisories/new). Include:

- the affected module and resource,
- the scenario (who can do what they should not be able to), and
- a minimal configuration or policy snippet that reproduces it.

You can expect an acknowledgement within 5 working days. Confirmed issues are fixed on `main`, released as a patch version and credited in the changelog unless you prefer otherwise.

## Scope

In scope: the Terraform code in this repository and the security claims in `docs/`.
Out of scope: vulnerabilities in AWS services or in Terraform and its providers themselves (report those to AWS or HashiCorp).

## Supported versions

Only the latest release receives security fixes.
