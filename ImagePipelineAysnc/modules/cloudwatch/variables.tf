variable "aws_region" {
  description = "AWS region for dashboard widget metrics"
  type        = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "lambda_function_name" {
  type = string
}

variable "sqs_queue_name" {
  type = string
}

variable "dlq_name" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "metrics_namespace" {
  description = "Custom CloudWatch namespace used in Lambda (must match METRICS_NAMESPACE env var)"
  type        = string
  default     = "ImagePipeline"
}

variable "alert_email" {
  description = "Email address to receive alarm notifications. Leave empty to skip."
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
