# Runbook: Responding to a security alarm

Every alarm from this control plane arrives on the `<prefix>-security-alerts` SNS topic. The alarm description names the CIS control and links here.

## First five minutes (any alarm)

1. **Acknowledge** in the on-call channel so nobody duplicates the work.
2. **Identify the actor and the action.** Query the CloudTrail log group for the alarm window:
   ```bash
   aws logs start-query \
     --log-group-name /aws/cloudtrail/<prefix> \
     --start-time $(date -d '-30 min' +%s) --end-time $(date +%s) \
     --query-string 'fields @timestamp, eventName, eventSource, userIdentity.arn, sourceIPAddress, userAgent, errorCode
       | sort @timestamp desc | limit 50'
   aws logs get-query-results --query-id <id>
   ```
3. **Match it to a change.** Is there an approved change ticket or a pipeline run for this actor and time?
   - **Yes:** note the ticket on the alert and close it as expected activity. If the same expected change alerts repeatedly, tune the detection in code rather than muting it.
   - **No, or unsure:** continue below and treat it as a potential incident.

## Triage by alarm

| Alarm | CIS | Treat as | What to check | Containment if malicious |
| --- | --- | --- | --- | --- |
| `root-account-usage` | 4.3 | **Incident until proven otherwise** | `sourceIPAddress`, `userAgent`, which API was called | Reset root password, rotate MFA, check for new IAM users/keys, contact AWS Support |
| `console-signin-without-mfa` | 4.2 | High | Which IAM user? Why does an IAM user with a password exist at all? | Disable the login profile, enforce MFA, move the person to role-based access |
| `console-authentication-failures` | 4.6 | Medium | Many usernames (spraying) or one (brute force)? Source IPs? | Block source at IdP/WAF, lock the targeted users |
| `unauthorized-api-calls` | 4.1 | Medium | A burst from one principal often means stolen credentials enumerating permissions | Revoke the principal's sessions (`AWSRevokeOlderSessions`), rotate keys |
| `iam-policy-changes` | 4.4 | High | Privilege escalation pattern: new policy version, attachment to self | Detach/revert the policy, revoke sessions of the actor |
| `cloudtrail-config-changes` | 4.5 | **Incident until proven otherwise** | `StopLogging` / `DeleteTrail` is a classic attacker step | Re-enable via `terraform apply`, then investigate the actor |
| `kms-key-disable-or-deletion` | 4.7 | High | Which key? Is deletion scheduled? | `aws kms cancel-key-deletion` + `enable-key` (30-day window) |
| `s3-bucket-policy-changes` | 4.8 | High | Was a bucket opened to `*` or another account? Cross-check IAM Access Analyzer | Revert the policy; account-level Block Public Access limits the blast radius |
| `config-changes` | 4.9 | High | Recorder stopped or delivery channel removed | Restart the recorder, investigate the actor |
| `security-group-changes` / `nacl-changes` | 4.10 / 4.11 | Medium | Was `0.0.0.0/0` opened on admin ports (22, 3389, databases)? | Revoke the rule |
| `network-gateway-changes` / `route-table-changes` / `vpc-changes` | 4.12–4.14 | Medium | New egress paths or peering to unknown accounts (possible exfiltration) | Remove the route, gateway or peering |
| `organizations-changes` | 4.15 | High | Account leaving the org, SCP detached | Re-attach the SCP, investigate |
| `break-glass-used` | — | High | Is there an incident ticket? See [break-glass.md](break-glass.md) | Revoke sessions if unexplained |
| `vcpu-quota-*` | — | Medium | Unknown instances, especially GPU families, in unusual regions | Stop the instances, revoke credentials, check billing |
| GuardDuty finding | — | By severity | Finding type and affected resource | Per the GuardDuty finding type remediation guidance |

## Revoking a compromised role's active sessions

Attach an inline deny for any session issued before now. This is what the console's *Revoke active sessions* button does:

```bash
aws iam put-role-policy --role-name <role> --policy-name AWSRevokeOlderSessions --policy-document '{
  "Version": "2012-10-17",
  "Statement": [{ "Effect": "Deny", "Action": "*", "Resource": "*",
    "Condition": { "DateLessThan": { "aws:TokenIssueTime": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'" } } }]
}'
```

## Close-out

- Record the timeline, actor, root cause and actions in the incident ticket.
- If the detection was noisy or missed something, change the detection **in code** (`modules/monitoring/main.tf`) through a reviewed pull request. Never mute an alarm in the console: that change would be invisible and would be reverted on the next apply.
