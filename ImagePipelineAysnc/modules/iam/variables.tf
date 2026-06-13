variable "project_name" {
  type = string
}

variable "input_bucket_arn" {
  type = string
}

variable "output_bucket_arn" {
  type = string
}

variable "dynamodb_table_arn" {
  type = string
}

variable "sqs_queue_arn" {
  description = "ARN of the main SQS queue Lambda will consume"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
