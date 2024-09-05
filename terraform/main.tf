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
module "network_module" {
  source = "./modules/network"
  base_name = var.base_name
}
module "s3_module" {
  source      = "./modules/storage"
  base_name = var.base_name
}
module "ec2_instance" {
  source   = "./modules/compute"
  base_name = var.base_name
  security_group_id = module.network_module.security_group_id
  subnet_id = module.network_module.subnet_id
  bucket_arn = module.s3_module.bucket_name
}