provider "aws" {
    region = "us-east-2"
}

module "vpc" {
  source = "./VPC"
  vpc_cidr_block = var.vpc_cidr_block
  tags = local.project_tags
  frontend_cidr_block = var.frontend_cidr_block
  availability_zone = var.availability_zone
  backend_cidr_block = var.backend_cidr_block

}