resource "aws_cloudtrail" "main" {
  name                          = "account-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.bucket
  is_multi_region_trail         = true
  enable_logging                = true
  include_global_service_events = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [
    aws_s3_bucket.cloudtrail_bucket,
    aws_s3_bucket_public_access_block.cloudtrail_block
  ]
}
