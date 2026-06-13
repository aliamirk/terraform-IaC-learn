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

variable "tags" {
  type    = map(string)
  default = {}
}
