# CIS AWS Foundations Benchmark v3.0.0, section 4 (Monitoring): a log metric
# filter and alarm for each high-risk API activity.
#
# Why metric filters on the trail's log group instead of EventBridge rules:
# events from global services (IAM, STS console sign-in, Organizations) are
# only delivered to EventBridge in us-east-1, so a rule deployed in any other
# region silently misses them. A multi-region trail delivers everything into
# one log group, so these filters see every region and every global service.
# See docs/adr/0002-metric-filters-over-eventbridge.md.

locals {
  alarms = {
    unauthorized-api-calls = {
      cis         = "4.1"
      description = "Unauthorized API calls (AccessDenied / UnauthorizedOperation)."
      pattern     = "{ (($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\")) && ($.sourceIPAddress != \"delivery.logs.amazonaws.com\") && ($.eventName != \"HeadBucket\") }"
      # CIS does not prescribe a threshold; single denials are routine noise
      # (console page loads, least-privilege roles probing). A burst is the signal.
      threshold = 10
    }
    console-signin-without-mfa = {
      cis         = "4.2"
      description = "Successful IAM user console sign-in without MFA."
      pattern     = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") && ($.userIdentity.type = \"IAMUser\") && ($.responseElements.ConsoleLogin = \"Success\") }"
      threshold   = 1
    }
    root-account-usage = {
      cis         = "4.3"
      description = "Any use of the root user."
      pattern     = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
      threshold   = 1
    }
    iam-policy-changes = {
      cis         = "4.4"
      description = "IAM policy created, changed, attached or detached."
      pattern     = "{ ($.eventName = \"DeleteGroupPolicy\") || ($.eventName = \"DeleteRolePolicy\") || ($.eventName = \"DeleteUserPolicy\") || ($.eventName = \"PutGroupPolicy\") || ($.eventName = \"PutRolePolicy\") || ($.eventName = \"PutUserPolicy\") || ($.eventName = \"CreatePolicy\") || ($.eventName = \"DeletePolicy\") || ($.eventName = \"CreatePolicyVersion\") || ($.eventName = \"DeletePolicyVersion\") || ($.eventName = \"AttachRolePolicy\") || ($.eventName = \"DetachRolePolicy\") || ($.eventName = \"AttachUserPolicy\") || ($.eventName = \"DetachUserPolicy\") || ($.eventName = \"AttachGroupPolicy\") || ($.eventName = \"DetachGroupPolicy\") }"
      threshold   = 1
    }
    cloudtrail-config-changes = {
      cis         = "4.5"
      description = "CloudTrail trail created, updated, deleted, started or stopped."
      pattern     = "{ ($.eventName = \"CreateTrail\") || ($.eventName = \"UpdateTrail\") || ($.eventName = \"DeleteTrail\") || ($.eventName = \"StartLogging\") || ($.eventName = \"StopLogging\") }"
      threshold   = 1
    }
    console-authentication-failures = {
      cis         = "4.6"
      description = "Failed console authentication attempts."
      pattern     = "{ ($.eventName = \"ConsoleLogin\") && ($.errorMessage = \"Failed authentication\") }"
      threshold   = 3
    }
    kms-key-disable-or-deletion = {
      cis         = "4.7"
      description = "Customer-managed KMS key disabled or scheduled for deletion."
      pattern     = "{ ($.eventSource = \"kms.amazonaws.com\") && (($.eventName = \"DisableKey\") || ($.eventName = \"ScheduleKeyDeletion\")) }"
      threshold   = 1
    }
    s3-bucket-policy-changes = {
      cis         = "4.8"
      description = "S3 bucket policy, ACL, CORS, lifecycle or replication changed."
      pattern     = "{ ($.eventSource = \"s3.amazonaws.com\") && (($.eventName = \"PutBucketAcl\") || ($.eventName = \"PutBucketPolicy\") || ($.eventName = \"PutBucketCors\") || ($.eventName = \"PutBucketLifecycle\") || ($.eventName = \"PutBucketReplication\") || ($.eventName = \"DeleteBucketPolicy\") || ($.eventName = \"DeleteBucketCors\") || ($.eventName = \"DeleteBucketLifecycle\") || ($.eventName = \"DeleteBucketReplication\")) }"
      threshold   = 1
    }
    config-changes = {
      cis         = "4.9"
      description = "AWS Config recorder or delivery channel changed or stopped."
      pattern     = "{ ($.eventSource = \"config.amazonaws.com\") && (($.eventName = \"StopConfigurationRecorder\") || ($.eventName = \"DeleteDeliveryChannel\") || ($.eventName = \"PutDeliveryChannel\") || ($.eventName = \"PutConfigurationRecorder\")) }"
      threshold   = 1
    }
    security-group-changes = {
      cis         = "4.10"
      description = "Security group created, deleted or rules changed."
      pattern     = "{ ($.eventName = \"AuthorizeSecurityGroupIngress\") || ($.eventName = \"AuthorizeSecurityGroupEgress\") || ($.eventName = \"RevokeSecurityGroupIngress\") || ($.eventName = \"RevokeSecurityGroupEgress\") || ($.eventName = \"CreateSecurityGroup\") || ($.eventName = \"DeleteSecurityGroup\") }"
      threshold   = 1
    }
    nacl-changes = {
      cis         = "4.11"
      description = "Network ACL created, deleted or changed."
      pattern     = "{ ($.eventName = \"CreateNetworkAcl\") || ($.eventName = \"CreateNetworkAclEntry\") || ($.eventName = \"DeleteNetworkAcl\") || ($.eventName = \"DeleteNetworkAclEntry\") || ($.eventName = \"ReplaceNetworkAclEntry\") || ($.eventName = \"ReplaceNetworkAclAssociation\") }"
      threshold   = 1
    }
    network-gateway-changes = {
      cis         = "4.12"
      description = "Internet or customer gateway created, attached, detached or deleted."
      pattern     = "{ ($.eventName = \"CreateCustomerGateway\") || ($.eventName = \"DeleteCustomerGateway\") || ($.eventName = \"AttachInternetGateway\") || ($.eventName = \"CreateInternetGateway\") || ($.eventName = \"DeleteInternetGateway\") || ($.eventName = \"DetachInternetGateway\") }"
      threshold   = 1
    }
    route-table-changes = {
      cis         = "4.13"
      description = "Route or route table created, replaced, disassociated or deleted."
      pattern     = "{ ($.eventSource = \"ec2.amazonaws.com\") && (($.eventName = \"CreateRoute\") || ($.eventName = \"CreateRouteTable\") || ($.eventName = \"ReplaceRoute\") || ($.eventName = \"ReplaceRouteTableAssociation\") || ($.eventName = \"DeleteRouteTable\") || ($.eventName = \"DeleteRoute\") || ($.eventName = \"DisassociateRouteTable\")) }"
      threshold   = 1
    }
    vpc-changes = {
      cis         = "4.14"
      description = "VPC or VPC peering created, modified or deleted."
      pattern     = "{ ($.eventName = \"CreateVpc\") || ($.eventName = \"DeleteVpc\") || ($.eventName = \"ModifyVpcAttribute\") || ($.eventName = \"AcceptVpcPeeringConnection\") || ($.eventName = \"CreateVpcPeeringConnection\") || ($.eventName = \"DeleteVpcPeeringConnection\") || ($.eventName = \"RejectVpcPeeringConnection\") }"
      threshold   = 1
    }
    organizations-changes = {
      cis         = "4.15"
      description = "AWS Organizations structure, account or policy changed."
      pattern     = "{ ($.eventSource = \"organizations.amazonaws.com\") && (($.eventName = \"AcceptHandshake\") || ($.eventName = \"AttachPolicy\") || ($.eventName = \"CreateAccount\") || ($.eventName = \"CreateOrganizationalUnit\") || ($.eventName = \"CreatePolicy\") || ($.eventName = \"DeclineHandshake\") || ($.eventName = \"DeleteOrganization\") || ($.eventName = \"DeleteOrganizationalUnit\") || ($.eventName = \"DeletePolicy\") || ($.eventName = \"DetachPolicy\") || ($.eventName = \"DisablePolicyType\") || ($.eventName = \"EnablePolicyType\") || ($.eventName = \"InviteAccountToOrganization\") || ($.eventName = \"LeaveOrganization\") || ($.eventName = \"MoveAccount\") || ($.eventName = \"RemoveAccountFromOrganization\") || ($.eventName = \"UpdatePolicy\") || ($.eventName = \"UpdateOrganizationalUnit\")) }"
      threshold   = 1
    }
  }

  enabled_alarms = { for k, v in local.alarms : k => v if !contains(var.disabled_alarms, k) }
}

resource "aws_cloudwatch_log_metric_filter" "this" {
  for_each = local.enabled_alarms

  name           = "${var.name_prefix}-${each.key}"
  log_group_name = var.log_group_name
  pattern        = each.value.pattern

  metric_transformation {
    name      = each.key
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.enabled_alarms

  alarm_name        = "${var.name_prefix}-${each.key}"
  alarm_description = "CIS AWS v3.0.0 ${each.value.cis}: ${each.value.description} Runbook: docs/runbooks/security-alarm-response.md"

  namespace           = var.metric_namespace
  metric_name         = aws_cloudwatch_log_metric_filter.this[each.key].metric_transformation[0].name
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = each.value.threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.alarm_topic_arn]

  tags = merge(var.tags, { "cis-control" = each.value.cis })
}
