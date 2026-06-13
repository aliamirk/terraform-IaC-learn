terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
  project_env = "${var.project_name}-${var.environment}"
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ── DynamoDB (no dependencies) ───────────────────────────────────────────────
module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = "${local.project_env}-image-metadata"
  tags       = local.tags
}

# ── S3 buckets (no dependencies) ────────────────────────────────────────────
module "s3" {
  source             = "./modules/s3"
  input_bucket_name  = "${local.project_env}-${var.input_bucket_suffix}"
  output_bucket_name = "${local.project_env}-${var.output_bucket_suffix}"
  tags               = local.tags
}

# ── IAM — needs bucket ARNs, DynamoDB ARN, SQS ARN ──────────────────────────
# We construct bucket ARNs directly (predictable pattern) to avoid
# a circular dependency between IAM and SQS.
module "iam" {
  source             = "./modules/iam"
  project_name       = local.project_env
  input_bucket_arn   = module.s3.input_bucket_arn
  output_bucket_arn  = module.s3.output_bucket_arn
  dynamodb_table_arn = module.dynamodb.table_arn
  sqs_queue_arn      = module.sqs.queue_arn
  tags               = local.tags

  depends_on = [module.s3, module.dynamodb, module.sqs]
}

# ── Lambda (needs IAM role, DynamoDB name, output bucket name) ───────────────
module "lambda" {
  source              = "./modules/lambda"
  project_name        = local.project_env
  environment         = var.environment
  lambda_role_arn     = module.iam.lambda_role_arn
  output_bucket_name  = module.s3.output_bucket_name
  dynamodb_table_name = module.dynamodb.table_name
  artifacts_bucket    = var.artifacts_bucket
  layer_s3_key        = var.layer_s3_key
  metrics_namespace   = var.metrics_namespace
  tags                = local.tags

  depends_on = [module.iam]
}

# ── SQS — needs S3 bucket info and Lambda ARN ────────────────────────────────
module "sqs" {
  source              = "./modules/sqs"
  project_name        = local.project_env
  input_bucket_arn    = module.s3.input_bucket_arn
  input_bucket_id     = module.s3.input_bucket_id
  lambda_function_arn = module.lambda.function_arn
  tags                = local.tags

  depends_on = [module.lambda, module.s3]
}

# ── CloudWatch dashboard + alarms ───────────────────────────────────────────
module "cloudwatch" {
  source               = "./modules/cloudwatch"
  project_name         = local.project_env
  environment          = var.environment
  lambda_function_name = module.lambda.function_name
  sqs_queue_name       = module.sqs.queue_name
  dlq_name             = module.sqs.dlq_name
  dynamodb_table_name  = module.dynamodb.table_name
  metrics_namespace    = var.metrics_namespace
  alert_email          = var.alert_email
  tags                 = local.tags

  depends_on = [module.lambda, module.sqs, module.dynamodb]
}
