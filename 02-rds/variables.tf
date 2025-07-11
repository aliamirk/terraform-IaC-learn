
# EC2 ------------------------------------------------------

variable "key_name" {
  description = "Name for the EC2 key pair"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

# RDS Database --------------------

variable "db_name" {
  description = "value"
  type = string
}

variable "db_storage" {
  description = "storage for rds db"
  type = number
}

variable "db_instance" {
  description = "instance type for rds db"
  type = string
}

variable "db_username" {
  description = "username for the rds database"
  type = string
}

variable "db_password" {
  description = "password for the rds database"
  type = string
}

variable "db_engine" {
  description = "engine type for the rds database"
  type = string
}

variable "engine_version" {
  description = "engine version for the database type"
  type = string
}