variable "name_prefix" {
  description = "Resurs nomlari va teglar uchun prefiks."
  type        = string

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix bo'sh bo'lmasligi kerak."
  }
}

variable "aws_region" {
  description = "IAM policy ARNlarida ishlatiladigan AWS mintaqasi."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region bo'sh bo'lmasligi kerak."
  }
}

variable "ci_trust_principal_arns" {
  description = "Infratuzilma roli uchun ixtiyoriy trust principal ARNlar. Bo'sh bo'lsa, hisob root ARN ishlatiladi; keyinchalik GitHub OIDC bilan almashtiriladi."
  type        = list(string)
  default     = []
}
