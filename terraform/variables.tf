# Asosiy kirish o'zgaruvchilari.
# Region uchun default berilmaydi; u tfvars yoki muhit orqali kiritiladi.
variable "aws_region" {
  description = "AWS mintaqasi (region)."
  type        = string
}

variable "project_name" {
  description = "Resurs nomlari va teglar uchun asosiy loyiha nomi."
  type        = string
  default     = "secure-cloud-infra"

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name bo'sh bo'lmasligi kerak."
  }
}

variable "environment" {
  description = "Muhit: dev, staging yoki prod."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment faqat dev, staging yoki prod bo'lishi kerak."
  }
}

variable "vpc_cidr" {
  description = "VPC uchun CIDR blok."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr yaroqli IPv4 CIDR bo'lishi kerak."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnetlar uchun CIDR bloklar ro'yxati."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && alltrue([for c in var.public_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Kamida 2 ta yaroqli public subnet CIDR kerak."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnetlar uchun CIDR bloklar ro'yxati."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2 && alltrue([for c in var.private_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Kamida 2 ta yaroqli private subnet CIDR kerak."
  }
}

variable "availability_zone_count" {
  description = "Subnetlar uchun ishlatiladigan availability zone soni."
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zone_count >= 2
    error_message = "availability_zone_count kamida 2 bo'lishi kerak."
  }
}

variable "availability_zones" {
  description = "Availability zones used by this deployment."
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}
