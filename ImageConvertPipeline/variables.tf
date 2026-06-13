variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used as a prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "input_bucket_suffix" {
  description = "Suffix for the input S3 bucket (must be globally unique)"
  type        = string
  default     = "images-input"
}

variable "output_bucket_suffix" {
  description = "Suffix for the output S3 bucket (must be globally unique)"
  type        = string
  default     = "images-output"
}
