

# ----------- EC2 Outputs -----------

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "ec2_az" {
  description = "Availability Zone of EC2 instance"
  value       = aws_instance.web_server.availability_zone
}


# ----------- RDS Outputs -----------

output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.database.id
}

output "rds_endpoint" {
  description = "RDS endpoint to connect to"
  value       = aws_db_instance.database.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.database.port
}

output "rds_engine_version" {
  description = "RDS engine version"
  value       = aws_db_instance.database.engine_version
}

output "rds_username" {
  description = "Master username for RDS"
  value       = aws_db_instance.database.username
  sensitive   = true
}

output "rds_db_name" {
  description = "Name of the default DB created"
  value       = aws_db_instance.database.db_name
}
