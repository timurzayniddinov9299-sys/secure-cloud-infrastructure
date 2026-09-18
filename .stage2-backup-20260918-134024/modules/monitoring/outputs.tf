output "cloudtrail_log_group_name" {
  description = "CloudTrail CloudWatch log group name."
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "cloudtrail_log_group_arn" {
  description = "CloudTrail CloudWatch log group ARN."
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}

output "cloudtrail_logs_role_arn" {
  description = "CloudTrail CloudWatch logging role ARN."
  value       = aws_iam_role.cloudtrail_logs.arn
}

output "security_alert_topic_arn" {
  description = "Dedicated KMS-encrypted security alert SNS topic ARN."
  value       = aws_sns_topic.security_alerts.arn
}
