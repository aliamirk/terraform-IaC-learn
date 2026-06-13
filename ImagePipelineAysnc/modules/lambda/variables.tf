variable "project_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "lambda_role_arn" {
  type = string
}

variable "output_bucket_name" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "artifacts_bucket" {
  description = "S3 bucket where lambda_layer.zip was uploaded before terraform apply"
  type        = string
}

variable "layer_s3_key" {
  description = "S3 key of the layer zip inside artifacts_bucket"
  type        = string
  default     = "pillow-layer.zip"
}

variable "metrics_namespace" {
  description = "Custom CloudWatch namespace for pipeline metrics"
  type        = string
  default     = "ImagePipeline"
}

variable "tags" {
  type    = map(string)
  default = {}
}
