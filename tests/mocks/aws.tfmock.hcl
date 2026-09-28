# Deterministic values for the mocked AWS provider. The provider validates ARN
# formats even under mocks, so any resource whose ARN feeds another resource
# needs a realistic default here.

mock_data "aws_caller_identity" {
  defaults = { account_id = "111122223333" }
}

mock_data "aws_region" {
  defaults = { region = "eu-central-1" }
}

mock_data "aws_partition" {
  defaults = { partition = "aws" }
}

mock_data "aws_iam_openid_connect_provider" {
  defaults = { arn = "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com" }
}

mock_resource "aws_kms_key" {
  defaults = {
    arn    = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    key_id = "00000000-0000-0000-0000-000000000000"
  }
}

mock_resource "aws_sns_topic" {
  defaults = { arn = "arn:aws:sns:eu-central-1:111122223333:cp-security-alerts" }
}

mock_resource "aws_cloudwatch_log_group" {
  defaults = { arn = "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/cloudtrail/cp" }
}

mock_resource "aws_iam_role" {
  defaults = { arn = "arn:aws:iam::111122223333:role/mock-role" }
}

mock_resource "aws_iam_policy" {
  defaults = { arn = "arn:aws:iam::111122223333:policy/mock-policy" }
}

mock_resource "aws_iam_openid_connect_provider" {
  defaults = { arn = "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com" }
}

mock_resource "aws_s3_bucket" {
  defaults = { arn = "arn:aws:s3:::mock-bucket" }
}

mock_resource "aws_cloudtrail" {
  defaults = { arn = "arn:aws:cloudtrail:eu-central-1:111122223333:trail/cp-trail" }
}

mock_resource "aws_kinesis_firehose_delivery_stream" {
  defaults = { arn = "arn:aws:firehose:eu-central-1:111122223333:deliverystream/cp-siem-export" }
}

mock_resource "aws_cloudwatch_event_rule" {
  defaults = { arn = "arn:aws:events:eu-central-1:111122223333:rule/cp-guardduty-findings" }
}

mock_resource "aws_cloudwatch_metric_alarm" {
  defaults = { arn = "arn:aws:cloudwatch:eu-central-1:111122223333:alarm:cp-mock" }
}

mock_resource "aws_ce_anomaly_monitor" {
  defaults = { arn = "arn:aws:ce::111122223333:anomalymonitor/00000000-0000-0000-0000-000000000000" }
}

mock_resource "aws_accessanalyzer_analyzer" {
  defaults = { arn = "arn:aws:access-analyzer:eu-central-1:111122223333:analyzer/cp-external-access" }
}
