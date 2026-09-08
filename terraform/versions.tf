# Terraform va AWS provider versiyalarini chegaralaydi.
# Aniq foydalaniladigan versiyalar .terraform.lock.hcl faylida qulflanadi.
terraform {
  required_version = "~> 1.15.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.100.0, < 6.0.0"
    }
  }
}
