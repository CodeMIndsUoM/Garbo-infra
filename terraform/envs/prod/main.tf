terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  project_name       = var.project_name
  ssh_allowed_cidr   = var.ssh_allowed_cidr
  tags               = local.common_tags
}

module "registry" {
  source = "../../modules/registry"

  project_name = var.project_name
  tags         = local.common_tags
}

module "secrets" {
  source = "../../modules/secrets"

  project_name         = var.project_name
  ssm_parameter_prefix = var.ssm_parameter_prefix
  tags                 = local.common_tags
}

module "compute" {
  source = "../../modules/compute"

  project_name         = var.project_name
  subnet_id            = module.network.public_subnet_id
  security_group_id    = module.network.security_group_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  ssm_parameter_prefix = var.ssm_parameter_prefix
  tags                 = local.common_tags
}

module "observability" {
  source = "../../modules/observability"

  project_name    = var.project_name
  ec2_instance_id = module.compute.instance_id
  tags            = local.common_tags
}
