output "cloudtrail_arn" {
  description = "CloudTrail trail ARN."
  value       = aws_cloudtrail.this.arn
}

output "cloudtrail_name" {
  description = "CloudTrail trail nomi."
  value       = aws_cloudtrail.this.name
}

output "log_bucket_name" {
  description = "Log S3 bucket nomi."
  value       = aws_s3_bucket.logs.bucket
}

output "log_bucket_arn" {
  description = "Log S3 bucket ARN."
  value       = aws_s3_bucket.logs.arn
}

output "vpc_flow_log_id" {
  description = "VPC Flow Log ID"
  value       = aws_flow_log.vpc.id
}

output "vpc_flow_log_cloudwatch_log_group" {
  description = "CloudWatch Log Group for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.arn
}

output "vpc_flow_log_role_arn" {
  description = "IAM Role ARN for VPC Flow Logs"
  value       = aws_iam_role.vpc_flow_logs.arn
}
