# --------------------------------
# Terraform configuration
# --------------------------------

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# --------------------------------
# Provider
# --------------------------------
provider "aws" {
  profile = "personal"
  region  = "ap-northeast-1"
}

# --------------------------------
# Variables
# --------------------------------
variable "project" {
  type = string
}

variable "env" {
  type = string
}

# --------------------------------
# Modules
# --------------------------------
module "network" {
  source = "../../modules/network"
  project = var.project
  env = var.env
  cidr_vpc     = "192.168.0.0/16"
  cidr_public1 = "192.168.1.0/24"
  cidr_public2 = "192.168.2.0/24"
  az_public1   = "ap-northeast-1c"
  az_public2   = "ap-northeast-1d"
}

module "security_group" {
  source = "../../modules/security_group"
  project = var.project
  env = var.env
}

module "app_server" {
  source = "../../modules/app_server"
  project = var.project
  env = var.env
  VPCID     = module.network.VPCID
  public1CID = module.network.public1CID
  public2CID = module.network.public2CID
  app_sg_id = module.security_group.app_sg_id
  opmng_sg_id = module.security_group.opmng_sg_id
}

module "db_server" {
  source = "../../modules/db_server"
  project = var.project
  env = var.env
  VPCID     = module.network.VPCID
  private1CID = module.network.private1CID
  private2CID = module.network.private2CID
  db_sg_id = module.security_group.db_sg_id
}


