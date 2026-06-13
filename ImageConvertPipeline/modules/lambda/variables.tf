variable "project_name" {
  type = string
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

variable "tags" {
  type    = map(string)
  default = {}
}
