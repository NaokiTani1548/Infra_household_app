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
}

module "security_group" {
  source = "../../modules/security_group"
  project = var.project
  env = var.env
  vpc_id = module.network.VPCID
}

module "s3" {
  source = "../../modules/S3"
  project = var.project
  env = var.env
  jar_local_path = "../../app_file/household_account_app-v1-0.0.1-SNAPSHOT.jar"
}

module "db_server" {
  source = "../../modules/db_server"
  project = var.project
  env = var.env
  VPCID     = module.network.VPCID
  private1CID = module.network.private1CID
  private2CID = module.network.private2CID
  public1CID = module.network.public1CID
  db_sg_id = module.security_group.db_sg_id
  opmng_sg_id = module.security_group.opmng_sg_id
}

module "app_server" {
  source = "../../modules/app_server"
  project = var.project
  env = var.env
  VPCID     = module.network.VPCID
  public1CID = module.network.public1CID
  app_sg_id = module.security_group.app_sg_id
  opmng_sg_id = module.security_group.opmng_sg_id
  jar_s3_bucket = module.s3.app_jar_bucket
  jar_s3_key = module.s3.app_jar_key
  rds_endpoint = module.db_server.db_private_ip
  db_username = module.db_server.mysql_username
  db_password = module.db_server.mysql_password
  key_pair = module.db_server.key_pair
}



