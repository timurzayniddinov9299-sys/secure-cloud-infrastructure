data "aws_caller_identity" "current" {}

output "cloudtrail_log_group_name" {
  description = "CloudTrail CloudWatch log group name (owned by logging module)."
  value       = var.cloudtrail_log_group_name
}

output "cloudtrail_log_group_arn" {
  description = "CloudTrail CloudWatch log group ARN (owned by logging module)."
  value       = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${var.cloudtrail_log_group_name}"
}

output "cloudtrail_logs_role_arn" {
  description = "CloudTrail CloudWatch Logs role ARN (owned by logging module)."
  value       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-cloudtrail-logs"
}

output "security_alert_topic_arn" {
  description = "Encrypted SNS topic ARN for security alerts."
  value       = aws_sns_topic.security_alerts.arn
}
