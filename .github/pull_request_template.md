## What and why

<!-- What does this change, and what problem or requirement does it address? -->

## Security and compliance impact

- [ ] No change to what any principal can do
- [ ] Changes a control listed in `docs/compliance-mapping.md` (mapping updated)
- [ ] Adds or changes a Checkov skip (justification written inline)
- [ ] Changes an alarm, detection or runbook (runbook updated)

## Verification

- [ ] `make ci` passes locally (fmt, validate, lint, tests, Checkov)
- [ ] New or changed security properties are covered by a `terraform test` assertion
- [ ] `make docs` run and generated READMEs committed
