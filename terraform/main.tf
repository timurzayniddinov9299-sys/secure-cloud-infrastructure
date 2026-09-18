# Root configuration: network va security modullarini chaqiradi.

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
  kms_key_arn = module.encryption.kms_key_arn
  vpc_id      = module.network.vpc_id
}

module "monitoring" {
  source = "../modules/monitoring"

  name_prefix               = "${var.project_name}-${var.environment}"
  aws_region                = var.aws_region
  kms_key_arn               = module.encryption.kms_key_arn
  cloudtrail_log_group_name = module.logging.cloudtrail_log_group_name
}

# Preserve Terraform state addresses if Stage2 was ever applied before the
# CloudTrail CloudWatch resources were moved from monitoring to logging.
moved {
  from = module.monitoring.aws_cloudwatch_log_group.cloudtrail
  to   = module.logging.aws_cloudwatch_log_group.cloudtrail
}

moved {
  from = module.monitoring.aws_iam_role.cloudtrail_logs
  to   = module.logging.aws_iam_role.cloudtrail_logs
}

moved {
  from = module.monitoring.aws_iam_policy.cloudtrail_logs
  to   = module.logging.aws_iam_policy.cloudtrail_logs
}

moved {
  from = module.monitoring.aws_iam_role_policy_attachment.cloudtrail_logs
  to   = module.logging.aws_iam_role_policy_attachment.cloudtrail_logs
}
