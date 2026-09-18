variable "name_prefix" {
  description = "Resource naming prefix."
  type        = string

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix cannot be empty."
  }
}

variable "aws_region" {
  description = "AWS region."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region cannot be empty."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN used for the encrypted security-alert SNS topic."
  type        = string

  validation {
    condition     = length(trimspace(var.kms_key_arn)) > 0
    error_message = "kms_key_arn cannot be empty."
  }
}

variable "cloudtrail_log_group_name" {
  description = "CloudTrail CloudWatch Log Group name owned by the logging module."
  type        = string

  validation {
    condition     = length(trimspace(var.cloudtrail_log_group_name)) > 0
    error_message = "cloudtrail_log_group_name cannot be empty."
  }
}
