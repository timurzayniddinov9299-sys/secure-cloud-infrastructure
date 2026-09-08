variable "name_prefix" {
  description = "Resurs nomlari va teglar uchun prefiks."
  type        = string

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix bo'sh bo'lmasligi kerak."
  }
}

variable "aws_region" {
  description = "KMS key policy shartlarida ishlatiladigan AWS mintaqasi."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region bo'sh bo'lmasligi kerak."
  }
}

variable "deletion_window_in_days" {
  description = "KMS kalitini o'chirishdan oldingi kutish davri (kunlarda)."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days 7 va 30 oralig'ida bo'lishi kerak."
  }
}
