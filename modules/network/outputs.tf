output "vpc_id" {
  description = "VPC identifikatori."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet identifikatorlari."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet identifikatorlari."
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "Public route table identifikatori."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private route table identifikatorlari."
  value       = aws_route_table.private[*].id
}
