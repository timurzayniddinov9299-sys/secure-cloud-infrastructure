# Hozirgi AWS hisobini bucket nomi va policy ARNlari uchun o'qish.
data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  region      = var.aws_region
  bucket_name = var.log_bucket_name != "" ? var.log_bucket_name : "${var.name_prefix}-${local.account_id}-cloudtrail-logs"
  trail_name  = "${var.name_prefix}-trail"
}

resource "aws_s3_bucket" "logs" {
  # checkov:skip=CKV2_AWS_62:Event notifications not required for CloudTrail log bucket
  # checkov:skip=CKV_AWS_18:Separate access logging not required for a CloudTrail log bucket
  # checkov:skip=CKV_AWS_144:Cross-region replication deferred to control cost
  # checkov:skip=CKV2_AWS_61:Lifecycle retention documented; will be added with storage policy
  bucket = local.bucket_name
}

resource "aws_sns_topic" "alerts" {
  name              = "${var.name_prefix}-cloudtrail-alerts"
  kms_master_key_id = var.kms_key_id
}

resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy: faqat CloudTrail yozishi va HTTPS majburiy.
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = "arn:aws:s3:::${local.bucket_name}"
        Condition = {
          StringLike = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${local.region}:${local.account_id}:trail/${local.trail_name}"
          }
        }
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${local.bucket_name}/AWSLogs/${local.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
          StringLike = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${local.region}:${local.account_id}:trail/${local.trail_name}"
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${local.bucket_name}",
          "arn:aws:s3:::${local.bucket_name}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "this" {
  # checkov:skip=CKV2_AWS_10:CloudTrail to S3 is primary; CloudWatch Logs integration deferred
  name                          = local.trail_name
  s3_bucket_name                = aws_s3_bucket.logs.bucket
  enable_log_file_validation    = true
  is_multi_region_trail         = true
  include_global_service_events = true
  kms_key_id                    = var.kms_key_id
  sns_topic_name                = aws_sns_topic.alerts.name

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.logs]
}
