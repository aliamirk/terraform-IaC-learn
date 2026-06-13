variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  description = "Short lowercase prefix for all resource names"
  type        = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "input_bucket_suffix" {
  type    = string
  default = "images-input"
}

variable "output_bucket_suffix" {
  type    = string
  default = "images-output"
}

variable "artifacts_bucket" {
  description = "S3 bucket holding the pre-built lambda_layer.zip (run build_layer.sh first)"
  type        = string
}

variable "layer_s3_key" {
  type    = string
  default = "pillow-layer.zip"
}

variable "metrics_namespace" {
  description = "Custom CloudWatch namespace for pipeline metrics"
  type        = string
  default     = "ImagePipeline"
}

variable "alert_email" {
  description = "Email to receive CloudWatch alarm notifications. Leave empty to skip."
  type        = string
  default     = ""
}
