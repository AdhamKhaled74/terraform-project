data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" { state = "available" }

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  az_a         = data.aws_availability_zones.available.names[0]
  az_b         = data.aws_availability_zones.available.names[1]
}

module "iam" {
  source = "./modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  ecr_repository_name = var.ecr_repository_name
  aws_region          = var.aws_region
  account_id          = data.aws_caller_identity.current.account_id
}

module "ec2" {
  source = "./modules/ec2"

  project_name        = var.project_name
  environment         = var.environment
  aws_region          = var.aws_region
  account_id          = data.aws_caller_identity.current.account_id
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  ecr_repository_name = var.ecr_repository_name
  instance_profile    = module.iam.ec2_instance_profile_name

  depends_on = [module.vpc, module.iam]
}

module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  app_sg_id          = module.ec2.app_sg_id
  db_username        = var.db_username
  db_password        = var.db_password

  depends_on = [module.vpc, module.ec2]
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name   = var.project_name
  environment    = var.environment
  aws_region     = var.aws_region
  asg_name       = module.ec2.asg_name
  alb_arn_suffix = module.ec2.alb_arn_suffix
  alert_email    = var.alert_email
  asg_policy_arn = module.ec2.scale_out_policy_arn

  depends_on = [module.ec2]
}
