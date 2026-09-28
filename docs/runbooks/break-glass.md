# Runbook: Break-glass access

**Controls:** ISO/IEC 27001:2022 A.8.2 (privileged access rights), A.5.26 (response to incidents) · NIST CSF 2.0 PR.AA-05

The `<prefix>-break-glass` role grants `AdministratorAccess`. It exists for when the normal access path is unavailable, for example:

- an identity provider outage (Entra ID, Okta, IAM Identity Center),
- a misconfigured permission set that locks out every admin, or
- an active incident that needs containment faster than the normal approval flow allows.

It is **not** a shortcut around change management.

## Safeguards built into the role

| Safeguard | Implementation |
| --- | --- |
| Named principals only | `break_glass_trusted_principal_arns`. Set this in production; the default trusts the account. |
| Fresh MFA | Trust policy requires `aws:MultiFactorAuthPresent = true` and `aws:MultiFactorAuthAge < 3600`. |
| Short sessions | `max_session_duration = 3600` |
| Every use is loud | The metric filter matches both the `AssumeRole` call and **every API call made with the session**. One event raises the `<prefix>-break-glass-used` alarm within about 1 minute of log delivery. |

## Using it

1. Open (or reference) an incident ticket **before** assuming the role, and announce in the incident channel that break-glass is being used.
2. Assume the role with MFA:
   ```bash
   aws sts assume-role \
     --role-arn arn:aws:iam::<account-id>:role/<prefix>-break-glass \
     --role-session-name "INC-1234-<your-name>" \
     --serial-number arn:aws:iam::<account-id>:mfa/<device> \
     --token-code <6-digit-code>
   ```
   Put the ticket number in `--role-session-name`. It appears in every CloudTrail event, so the audit trail links back to the ticket.
3. Do only what the incident requires. Prefer read and contain actions over irreversible ones.
4. Let the session expire, or discard the credentials, as soon as the task is done.

## After every use (mandatory)

1. Export the session's activity for the ticket:
   ```bash
   aws logs filter-log-events \
     --log-group-name /aws/cloudtrail/<prefix> \
     --start-time <epoch-ms> \
     --filter-pattern '{ $.userIdentity.sessionContext.sessionIssuer.userName = "<prefix>-break-glass" }'
   ```
2. A second person reviews every action against the ticket.
3. Rotate or re-seal whatever credentials were used to reach the role (e.g. the break-glass IAM user's password and MFA).
4. Record the review outcome. Any use without a matching ticket is treated as a **security incident**.
