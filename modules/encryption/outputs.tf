output "kms_key_id" {
  description = "KMS kalit identifikatori."
  value       = aws_kms_key.this.key_id
}

output "kms_key_arn" {
  description = "KMS kalit ARN."
  value       = aws_kms_key.this.arn
}

output "kms_alias_name" {
  description = "KMS kalit alias nomi."
  value       = aws_kms_alias.this.name
}

output "kms_alias_arn" {
  description = "KMS kalit alias ARN."
  value       = aws_kms_alias.this.arn
}
