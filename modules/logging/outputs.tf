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
