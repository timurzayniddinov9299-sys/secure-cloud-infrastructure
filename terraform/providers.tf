# AWS provider konfiguratsiyasi.
# Credential yoki secret bu faylda YOZILMAYDI. Provider ularni
# muhit o'zgaruvchilari yoki AWS CLI konfiguratsiyasidan oladi.
provider "aws" {
  region = var.aws_region
}
