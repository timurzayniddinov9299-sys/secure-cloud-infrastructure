variable "name_prefix" {
  description = "Resurs nomlari va teglar uchun prefiks."
  type        = string

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix bo'sh bo'lmasligi kerak."
  }
}

variable "vpc_cidr" {
  description = "VPC uchun CIDR blok."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr yaroqli IPv4 CIDR bo'lishi kerak."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnetlar uchun CIDR bloklar ro'yxati."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && alltrue([for c in var.public_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Kamida 2 ta yaroqli public subnet CIDR kerak."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnetlar uchun CIDR bloklar ro'yxati."
  type        = list(string)

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
  description = "Ixtiyoriy aniq availability zone ro'yxati. Bo'sh bo'lsa, AWS data source orqali olinadi."
  type        = list(string)
  default     = []
}
