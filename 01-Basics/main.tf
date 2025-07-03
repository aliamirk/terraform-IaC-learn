terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "test_server" {
  ami = ""
  instance_type = "t2.micro"
  subnet_id = ""
  key_name = "server_key"

  tags = {
    Name = "Server-1"
  }
}

