variable "aws_region" {
  description = "AWS mintaqasi (region)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Loyiha resurslari uchun asosiy nom."
  type        = string
  default     = "secure-cloud-infra"
}

variable "environment" {
  description = "Muhit: dev, staging yoki prod."
  type        = string
  default     = "dev"
}
