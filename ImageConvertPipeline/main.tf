terraform {
  required_version = ">=1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "dynamodb" {
  source = "./modules/dynamodb"

  table_name = "${var.project_name}-${var.environment}-image-metadata"
  tags = local.tags
}

module "lambda" {
  source = "./modules/lambda"

  project_name        = "${var.project_name}-${var.environment}"
  lambda_role_arn = module.iam.lambda_role_arn
  output_bucket_name = "${var.project_name}-${var.environment}-${var.output_bucket_suffix}"
  dynamodb_table_name = module.dynamodb.table_name
  tags                = local.tags

  depends_on = [module.iam]
}

module "s3" {
  source = "./modules/s3"

  input_bucket_name    = "${var.project_name}-${var.environment}-${var.input_bucket_suffix}"
  output_bucket_name   = "${var.project_name}-${var.environment}-${var.output_bucket_suffix}"
  lambda_function_arn  = module.lambda.function_arn
  lambda_function_name = module.lambda.function_name
  tags                 = local.tags

  depends_on = [module.lambda]
}


module "iam" {
  source             = "./modules/iam"
  project_name       = "${var.project_name}-${var.environment}"
  input_bucket_arn   = "arn:aws:s3:::${var.project_name}-${var.environment}-${var.input_bucket_suffix}"
  output_bucket_arn  = "arn:aws:s3:::${var.project_name}-${var.environment}-${var.output_bucket_suffix}"
  dynamodb_table_arn = module.dynamodb.table_arn
  tags               = local.tags
}
