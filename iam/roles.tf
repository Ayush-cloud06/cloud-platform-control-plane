data "aws_caller_identity" "current" {}

# ---- Admin Role ( used by humans via SSO / assume-role) ----

resource "aws_iam_role" "admin_role" {
  name = "aws-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


# ---- Security Role (read-only + security services) ----

resource "aws_iam_role" "security_role" {
  name = "aws-security-role"

  assume_role_policy = aws_iam_role.admin_role.assume_role_policy
}

resource "aws_iam_role_policy_attachment" "security_readonly" {
  role       = aws_iam_role.security_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# ---- Automation Role (Terraform / CI) ----

resource "aws_iam_role" "automation_role" {
  name = "aws-automation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  permissions_boundary = aws_iam_policy.permission_boundary.arn
}

resource "aws_iam_role_policy_attachment" "automation_poweruser" {
  role       = aws_iam_role.automation_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}
