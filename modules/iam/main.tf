# Hozirgi AWS hisobini ARN yaratish uchun o'qish. Real API chaqiruvi talab qilinmaydi.
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = var.aws_region

  ci_trust_principals = length(var.ci_trust_principal_arns) > 0 ? var.ci_trust_principal_arns : ["arn:aws:iam::${local.account_id}:root"]
}

# A. Infratuzilma boshqaruv roli.
resource "aws_iam_role" "infrastructure" {
  name = "${var.name_prefix}-infrastructure-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = local.ci_trust_principals
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# B. Web/application ish yuklamasi uchun service role.
resource "aws_iam_role" "workload" {
  name = "${var.name_prefix}-workload-role"

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
}

# C. Monitoring/logging uchun service role.
resource "aws_iam_role" "monitoring" {
  name = "${var.name_prefix}-monitoring-role"

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
}

# Infratuzilma deploy policy: faqat VPC/tarmoq/xavfsizlik resurslarini boshqarish.
# Describe amallari AWS'da resource-level emas, shuning uchun faqat ularga Resource "*" beriladi.
resource "aws_iam_policy" "infrastructure_deploy" {
  name        = "${var.name_prefix}-infrastructure-deploy-policy"
  description = "Terraform uchun tarmoq, IAM, KMS va CloudTrail resurslarini boshqarish huquqlari"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeNetworkAcls"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:ReplaceRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = [
          "arn:aws:ec2:${local.region}:${local.account_id}:vpc/*",
          "arn:aws:ec2:${local.region}:${local.account_id}:subnet/*",
          "arn:aws:ec2:${local.region}:${local.account_id}:internet-gateway/*",
          "arn:aws:ec2:${local.region}:${local.account_id}:route-table/*",
          "arn:aws:ec2:${local.region}:${local.account_id}:security-group/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudtrail:CreateTrail",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail",
          "cloudtrail:GetTrail",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:StartLogging",
          "cloudtrail:StopLogging",
          "cloudtrail:PutEventSelectors",
          "cloudtrail:GetEventSelectors"
        ]
        Resource = ["arn:aws:cloudtrail:${local.region}:${local.account_id}:trail/${var.name_prefix}-*"]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudtrail:DescribeTrails"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketVersioning",
          "s3:GetBucketVersioning",
          "s3:PutBucketEncryption",
          "s3:GetBucketEncryption",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketAcl",
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.name_prefix}-*",
          "arn:aws:s3:::${var.name_prefix}-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:SetTopicAttributes",
          "sns:GetTopicAttributes",
          "sns:TagResource",
          "sns:UntagResource"
        ]
        Resource = ["arn:aws:sns:${local.region}:${local.account_id}:${var.name_prefix}-*"]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:RevokeGrant",
          "kms:EnableKeyRotation",
          "kms:DisableKeyRotation",
          "kms:GetKeyRotationStatus",
          "kms:PutKeyPolicy",
          "kms:GetKeyPolicy",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:CreateAlias",
          "kms:UpdateAlias",
          "kms:DeleteAlias"
        ]
        Resource = ["arn:aws:kms:${local.region}:${local.account_id}:key/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:ListAliases"]
        Resource = "*"
      }
    ]
  })
}

# Web/application ish yuklamasi uchun minimal policy.
resource "aws_iam_policy" "workload" {
  name        = "${var.name_prefix}-workload-policy"
  description = "Web/application uchun CloudWatch Logs va SSM Parameter huquqlari"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup"]
        Resource = ["arn:aws:logs:${local.region}:${local.account_id}:*"]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/${var.name_prefix}/*:log-stream:*"]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = ["arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.name_prefix}/*"]
      }
    ]
  })
}

# Monitoring/logging uchun minimal policy.
resource "aws_iam_policy" "monitoring" {
  name        = "${var.name_prefix}-monitoring-policy"
  description = "Monitoring uchun CloudWatch Logs va metric huquqlari"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup"]
        Resource = ["arn:aws:logs:${local.region}:${local.account_id}:*"]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/${var.name_prefix}/*:log-stream:*"]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_deploy" {
  role       = aws_iam_role.infrastructure.name
  policy_arn = aws_iam_policy.infrastructure_deploy.arn
}

resource "aws_iam_role_policy_attachment" "workload" {
  role       = aws_iam_role.workload.name
  policy_arn = aws_iam_policy.workload.arn
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = aws_iam_policy.monitoring.arn
}
