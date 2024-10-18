terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.16"
    }
  }
  required_version = ">=1.2.0"
}
provider "aws" {
  region = "us-east-2"
}
provider "vault" {
  address = var.vault_address
  token = var.vault_token
}
provider "random" {}
module "network_module" {
  source = "./modules/network"
  base_name = var.base_name
  nat_instance_id = module.ec2_instance.nat_instance_id
}
module "s3_module" {
  source      = "./modules/storage"
  base_name = var.base_name
}
module "ec2_instance" {
  source   = "./modules/compute"
  base_name = var.base_name
  security_group_ids = module.network_module.sec_grp_ids
  public_subnet_id = module.network_module.public_subnet_id
  bucket_arn = module.s3_module.bucket_name
  private_subnet_id = module.network_module.private_subnet_id
  pub_path = var.pub_path
  key_prefix = var.key_prefix
}
