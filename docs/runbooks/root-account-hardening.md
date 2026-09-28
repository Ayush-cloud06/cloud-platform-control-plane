# Runbook: Root user hardening

**When:** once, before deploying the control plane into a new account, and during every quarterly access review.
**Who:** account owner, with a second person as witness.
**Controls:** CIS AWS v3.0.0 1.4, 1.5, 1.6, 1.7 · ISO/IEC 27001:2022 A.8.2, A.8.5

Terraform can't manage the root user's credentials, so this is a manual control. The control plane enforces the detective side: any root use raises the `root-account-usage` alarm (CIS 4.3).

## Procedure

1. Sign in as root using the account email and password.
2. **Enable MFA** (CIS 1.5). Use a hardware security key (FIDO2) or a hardware TOTP token (CIS 1.6, level 2). Register at least two devices so losing one doesn't lock you out of the account.
3. **Delete all root access keys** (CIS 1.4): *Security credentials → Access keys → Delete*.
4. Set a unique password of 20+ characters, generated and stored in the company password manager.
5. Confirm the account contact details and the security alternate contact are current: *Account → Alternate contacts → Security*. AWS sends abuse and compromise notices there.
6. Store the MFA devices and recovery details in a physically secured location (a safe) under dual control.
7. Sign out. Do not use root for day-to-day work (CIS 1.7); use the `<prefix>-admin` role with MFA instead.

## Evidence for auditors

```bash
# Expect: AccountMFAEnabled = 1 and AccountAccessKeysPresent = 0
aws iam get-account-summary \
  --query 'SummaryMap.{mfa:AccountMFAEnabled,rootKeys:AccountAccessKeysPresent}'

# Credential report: check the <root_account> row
aws iam generate-credential-report >/dev/null && sleep 5
aws iam get-credential-report --query Content --output text | base64 -d | head -2
```

Record the date, operator, witness and command output in the access review log.

## Tasks that genuinely need root

A few actions can only be performed as root: closing the account, changing the root email, restoring IAM admin permissions if every admin is locked out, and some billing and tax settings. Performing one is a planned change: raise a change ticket first so the `root-account-usage` alarm can be matched to it.
