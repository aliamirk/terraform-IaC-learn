variable "input_bucket_name" {
  type = string
}

variable "output_bucket_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
