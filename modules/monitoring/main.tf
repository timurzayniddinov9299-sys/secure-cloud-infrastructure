# CloudTrail log group is owned by the logging module. This module owns
# the security metrics, alarms and notification topic.

resource "aws_sns_topic" "security_alerts" {
  name              = "${var.name_prefix}-security-alerts"
  kms_master_key_id = var.kms_key_arn
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "unauthorized_api_calls"
  log_group_name = var.cloudtrail_log_group_name

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
  log_group_name = var.cloudtrail_log_group_name

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
  log_group_name = var.cloudtrail_log_group_name

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
  log_group_name = var.cloudtrail_log_group_name

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
