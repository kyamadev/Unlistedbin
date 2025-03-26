provider "aws" {
  region = var.aws_region
}

# Terraform 状態管理用の S3 バケット設定
terraform {
  backend "s3" {
    bucket = "unlistedbin-terraform-state"
    key    = "unlistedbin/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

# Cognito User Pool
resource "aws_cognito_user_pool" "unlistedbin_users" {
  name = "${var.project_name}-users-${var.environment}"
  
  auto_verify {
    email = true
  }
  
  username_attributes      = ["email"]
  alias_attributes         = ["preferred_username"]
  
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }
  
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }
  
  schema {
    name                = "preferred_username"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }
  
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Cognito App Client
resource "aws_cognito_user_pool_client" "app_client" {
  name                   = "${var.project_name}-app-client-${var.environment}"
  user_pool_id           = aws_cognito_user_pool.unlistedbin_users.id
  generate_secret        = false
  refresh_token_validity = 30
  access_token_validity  = 1
  id_token_validity      = 1
  
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
  
  supported_identity_providers = ["COGNITO"]
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

# VPC 設定
module "vpc" {
  source = "./modules/vpc"
  
  environment  = var.environment
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

# RDS MySQL インスタンス
module "rds" {
  source = "./modules/rds"
  
  environment     = var.environment
  project_name    = var.project_name
  db_name         = var.db_name
  db_username     = var.db_username
  db_password     = var.db_password
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  security_groups = [module.vpc.db_security_group_id]
}

# Lambda 関数と API Gateway 設定
module "api" {
  source = "./modules/api"
  
  environment       = var.environment
  project_name      = var.project_name
  lambda_name       = "${var.project_name}-api-${var.environment}"
  lambda_handler    = "main"
  runtime           = "go1.x"
  cognito_user_pool = aws_cognito_user_pool.unlistedbin_users.id
  cognito_client_id = aws_cognito_user_pool_client.app_client.id
  api_domain_name   = var.api_domain_name
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_groups   = [module.vpc.lambda_security_group_id]
  db_endpoint       = module.rds.db_endpoint
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  r2_bucket         = var.r2_bucket
  r2_access_key     = var.r2_access_key
  r2_secret_key     = var.r2_secret_key
  r2_endpoint       = var.r2_endpoint
}

# SES 設定
resource "aws_ses_email_identity" "sender" {
  email = var.ses_sender_email
}