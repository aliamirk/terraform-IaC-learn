variable "table_name" {
  description = "name of table"
  type = string
}

variable "tags" {
  description = "tags to apply"
  type = map(string)
  default = {}
}