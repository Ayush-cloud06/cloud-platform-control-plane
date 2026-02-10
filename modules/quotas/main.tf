# To enforce a limit on VPCs to prevent "Shadow IT" or cost runaway

resource "aws_servicequotas_service_quota" "vpc_limit" {
  quota_code   = "L-F678F1CE" # Quota code for VPCs per region
  service_code = "vpc"
  value        = var.vpc_quota
}
