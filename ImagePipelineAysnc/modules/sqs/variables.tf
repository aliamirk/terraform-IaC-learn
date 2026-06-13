variable "project_name" {
  type = string
}

variable "input_bucket_arn" {
  type        = string
  description = "ARN of the S3 input bucket (used in queue policy condition)"
}

variable "input_bucket_id" {
  type        = string
  description = "ID (name) of the S3 input bucket for the notification resource"
}

variable "lambda_function_arn" {
  type        = string
  description = "ARN of the Lambda function that will consume the queue"
}

variable "tags" {
  type    = map(string)
  default = {}
}
