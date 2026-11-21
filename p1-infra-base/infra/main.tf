provider "aws" {
  region = var.region
}

# Network 생성 모듈
module "network" {
  source = "../modules/network"

  region   = var.region
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name
  igw_name = var.igw_name

  public_subnets = {
    "1" = {
      cidr = var.pub_sub_1_cidr
      az   = var.pub_sub_1_az
      name = var.pub_sub_1_name
    }
    "2" = {
      cidr = var.pub_sub_2_cidr
      az   = var.pub_sub_2_az
      name = var.pub_sub_2_name
    }
  }

  private_subnets = {
    "1" = {
      cidr = var.pri_sub_1_cidr
      az   = var.pri_sub_1_az
      name = var.pri_sub_1_name
    }
    "2" = {
      cidr = var.pri_sub_2_cidr
      az   = var.pri_sub_2_az
      name = var.pri_sub_2_name
    }
  }

  nat_eip_name          = var.nat_eip_name
  nat_gateway_name      = var.nat_gateway_name
  nat_public_subnet_key = var.nat_public_subnet_key

  public_route_table_name  = var.public_route_table_name
  private_route_table_name = var.private_route_table_name
}

# EKS 생성 모듈
module "eks" {
  source = "../modules/eks"

  depends_on = [module.network]

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  node_group_name    = var.node_group_name
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  node_volume_size   = var.node_volume_size
  node_key_name      = var.node_key_name
}
