output "infrastructure_role_arn" {
  description = "Infratuzilma boshqaruv roli ARN."
  value       = aws_iam_role.infrastructure.arn
}

output "workload_role_arn" {
  description = "Web/application ish yuklamasi roli ARN."
  value       = aws_iam_role.workload.arn
}

output "monitoring_role_arn" {
  description = "Monitoring/logging roli ARN."
  value       = aws_iam_role.monitoring.arn
}

output "infrastructure_deploy_policy_arn" {
  description = "Infratuzilma deploy policy ARN."
  value       = aws_iam_policy.infrastructure_deploy.arn
}

output "workload_policy_arn" {
  description = "Web/application policy ARN."
  value       = aws_iam_policy.workload.arn
}

output "monitoring_policy_arn" {
  description = "Monitoring/logging policy ARN."
  value       = aws_iam_policy.monitoring.arn
}
