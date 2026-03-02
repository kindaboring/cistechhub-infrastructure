terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "cistechhub"
      ManagedBy   = "terraform"
      Purpose     = "AWS-Migration-Learning"
    }
  }
}

# Networking Module - Creates VPC, subnets, gateways
module "networking" {
  source = "../../modules/networking"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Storage Module - Creates S3 bucket for uploads
module "storage" {
  source = "../../modules/cistechhub-storage"

  environment     = var.environment
  allowed_origins = ["*"]  # Will be updated with actual domain when available
}

# Cistechhub Application Server (Free Tier)
module "cistechhub" {
  source = "../../modules/cistechhub-free-tier"

  environment        = var.environment
  aws_region         = var.aws_region
  vpc_id             = module.networking.vpc_id
  public_subnet_id   = module.networking.public_subnet_ids[0]
  instance_type      = var.instance_type
  key_name           = var.key_name
  ssh_allowed_cidrs  = var.ssh_allowed_cidrs

  uploads_bucket_name = module.storage.uploads_bucket_name
  uploads_bucket_arn  = module.storage.uploads_bucket_arn

  # Optional: Google OAuth credentials
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  google_redirect_uri  = var.google_redirect_uri
}
