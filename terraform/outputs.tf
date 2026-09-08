# Network va security modullarining asosiy chiqishlari.
output "aws_region" {
  description = "Tanlangan AWS mintaqasi."
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC identifikatori."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet identifikatorlari."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet identifikatorlari."
  value       = module.network.private_subnet_ids
}

output "public_route_table_id" {
  description = "Public route table identifikatori."
  value       = module.network.public_route_table_id
}

output "private_route_table_ids" {
  description = "Private route table identifikatorlari."
  value       = module.network.private_route_table_ids
}

output "web_security_group_id" {
  description = "Web layer security group identifikatori."
  value       = module.security.web_security_group_id
}

output "application_security_group_id" {
  description = "Application layer security group identifikatori."
  value       = module.security.application_security_group_id
}

output "infrastructure_role_arn" {
  description = "Infratuzilma boshqaruv roli ARN."
  value       = module.iam.infrastructure_role_arn
}

output "workload_role_arn" {
  description = "Web/application ish yuklamasi roli ARN."
  value       = module.iam.workload_role_arn
}

output "monitoring_role_arn" {
  description = "Monitoring/logging roli ARN."
  value       = module.iam.monitoring_role_arn
}

output "kms_key_arn" {
  description = "KMS kalit ARN."
  value       = module.encryption.kms_key_arn
}

output "kms_alias_name" {
  description = "KMS kalit alias nomi."
  value       = module.encryption.kms_alias_name
}

output "cloudtrail_arn" {
  description = "CloudTrail trail ARN."
  value       = module.logging.cloudtrail_arn
}

output "cloudtrail_name" {
  description = "CloudTrail trail nomi."
  value       = module.logging.cloudtrail_name
}

output "log_bucket_name" {
  description = "Log S3 bucket nomi."
  value       = module.logging.log_bucket_name
}

output "log_bucket_arn" {
  description = "Log S3 bucket ARN."
  value       = module.logging.log_bucket_arn
}
