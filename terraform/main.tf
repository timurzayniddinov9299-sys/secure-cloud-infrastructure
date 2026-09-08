# Root konfiguratsiya: network va security modullarini chaqiradi.
# AWS resurslari hali real yaratilmaydi; kod keyingi bosqichda apply uchun tayyor.

module "network" {
  source = "../modules/network"

  name_prefix             = "${var.project_name}-${var.environment}"
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  availability_zone_count = var.availability_zone_count
  availability_zones      = var.availability_zones
}

module "security" {
  source = "../modules/security"

  name_prefix = "${var.project_name}-${var.environment}"
  vpc_id      = module.network.vpc_id
}

module "iam" {
  source = "../modules/iam"

  name_prefix = "${var.project_name}-${var.environment}"
  aws_region  = var.aws_region
}

module "encryption" {
  source = "../modules/encryption"

  name_prefix = "${var.project_name}-${var.environment}"
  aws_region  = var.aws_region
}

module "logging" {
  source = "../modules/logging"

  name_prefix = "${var.project_name}-${var.environment}"
  aws_region  = var.aws_region
  kms_key_id  = module.encryption.kms_key_id
}
