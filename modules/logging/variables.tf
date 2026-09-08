variable "name_prefix" {
  description = "Resurs nomlari va teglar uchun prefiks."
  type        = string

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix bo'sh bo'lmasligi kerak."
  }
}

variable "aws_region" {
  description = "CloudTrail va bucket policy ARNlarida ishlatiladigan AWS mintaqasi."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region bo'sh bo'lmasligi kerak."
  }
}

variable "kms_key_id" {
  description = "CloudTrail jurnallarini shifrlash uchun KMS kalit identifikatori."
  type        = string

  validation {
    condition     = length(trimspace(var.kms_key_id)) > 0
    error_message = "kms_key_id bo'sh bo'lmasligi kerak."
  }
}

variable "log_bucket_name" {
  description = "Ixtiyoriy aniq log bucket nomi. Bo'sh bo'lsa, name_prefix va account ID asosida avtomatik yaratiladi."
  type        = string
  default     = ""
}
