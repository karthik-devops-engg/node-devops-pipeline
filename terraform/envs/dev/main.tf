locals {
  name = "node-devops"
}

module "vpc" {
  source = "../../modules/vpc"
  name   = local.name
}

module "security" {
  source   = "../../modules/security"
  name     = local.name
  vpc_id   = module.vpc.vpc_id
  ssh_cidr = var.my_ip_cidr
}

resource "aws_key_pair" "deployer" {
  key_name   = "${local.name}-key"
  public_key = file(pathexpand(var.public_key_path))
}

module "app" {
  source             = "../../modules/ec2"
  name               = local.name
  role               = "app"
  instance_count     = 2
  instance_type      = var.app_instance_type
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security.app_sg_id]
  key_name           = aws_key_pair.deployer.key_name
}

module "monitoring" {
  source             = "../../modules/ec2"
  name               = local.name
  role               = "monitoring"
  instance_count     = 1
  instance_type      = var.monitoring_instance_type
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security.monitoring_sg_id]
  key_name           = aws_key_pair.deployer.key_name
  root_volume_size   = 30
}

module "alb" {
  source              = "../../modules/alb"
  name                = local.name
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_id   = module.security.alb_sg_id
  target_instance_ids = module.app.instance_ids
}
