data "aws_caller_identity" "current" {}

locals {
  account_id     = data.aws_caller_identity.current.account_id
  region         = var.aws_region
  trail_name     = "${var.name_prefix}-trail"
  log_group_name = "/aws/cloudtrail/${var.name_prefix}"
  cloudtrail_arn = "arn:aws:cloudtrail:${local.region}:${local.account_id}:trail/${local.trail_name}"
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = local.log_group_name
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn

  tags = {
    Name = "${var.name_prefix}-cloudtrail"
  }
}

resource "aws_iam_role" "cloudtrail_logs" {
  name = "${var.name_prefix}-cloudtrail-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
            "aws:SourceArn"     = local.cloudtrail_arn
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cloudtrail_logs" {
  name        = "${var.name_prefix}-cloudtrail-logs-policy"
  description = "Allows CloudTrail to write events to its dedicated CloudWatch log group."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = [
          "arn:aws:logs:${local.region}:${local.account_id}:log-group:${local.log_group_name}:log-stream:${local.account_id}_CloudTrail_${local.region}*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_logs" {
  role       = aws_iam_role.cloudtrail_logs.name
  policy_arn = aws_iam_policy.cloudtrail_logs.arn
}

resource "aws_sns_topic" "security_alerts" {
  name              = "${var.name_prefix}-security-alerts"
  kms_master_key_id = var.kms_key_arn
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "unauthorized_api_calls"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name          = "UnauthorizedApiCalls"
    namespace     = "${var.name_prefix}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "console_login_without_mfa" {
  name           = "console_login_without_mfa"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"

  metric_transformation {
    name          = "ConsoleLoginWithoutMFA"
    namespace     = "${var.name_prefix}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "root_account_activity" {
  name           = "root_account_activity"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ $.userIdentity.type = \"Root\" }"

  metric_transformation {
    name          = "RootAccountActivity"
    namespace     = "${var.name_prefix}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "kms_key_protection_change" {
  name           = "kms_key_protection_change"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ ($.eventSource = \"kms.amazonaws.com\") && (($.eventName = \"DisableKey\") || ($.eventName = \"ScheduleKeyDeletion\")) }"

  metric_transformation {
    name          = "KmsKeyProtectionChange"
    namespace     = "${var.name_prefix}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.name_prefix}-unauthorized-api-calls"
  alarm_description   = "Detects unauthorized API calls or access-denied errors in CloudTrail events."
  namespace           = "${var.name_prefix}/Security"
  metric_name         = "UnauthorizedApiCalls"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "console_login_without_mfa" {
  alarm_name          = "${var.name_prefix}-console-login-without-mfa"
  alarm_description   = "Detects console logins for which CloudTrail reports that MFA was not used."
  namespace           = "${var.name_prefix}/Security"
  metric_name         = "ConsoleLoginWithoutMFA"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "root_account_activity" {
  alarm_name          = "${var.name_prefix}-root-account-activity"
  alarm_description   = "Detects activity performed by the AWS account root user."
  namespace           = "${var.name_prefix}/Security"
  metric_name         = "RootAccountActivity"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "kms_key_protection_change" {
  alarm_name          = "${var.name_prefix}-kms-key-protection-change"
  alarm_description   = "Detects KMS key disable or scheduled-deletion events."
  namespace           = "${var.name_prefix}/Security"
  metric_name         = "KmsKeyProtectionChange"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}
