variable "name_prefix" {
  description = "Resurs nomlari va teglar uchun prefiks."
  type        = string

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix bo'sh bo'lmasligi kerak."
  }
}

variable "vpc_id" {
  description = "Security groups yaratiladigan VPC identifikatori."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id bo'sh bo'lmasligi kerak."
  }
}
