output "web_security_group_id" {
  description = "Web layer security group identifikatori."
  value       = aws_security_group.web.id
}

output "application_security_group_id" {
  description = "Application layer security group identifikatori."
  value       = aws_security_group.application.id
}
