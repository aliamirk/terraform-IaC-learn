output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.ec2_instance.public_ip
}

output "private_key_path" {
  description = "Location of the private key PEM file"
  value       = local_file.private_key.filename
}
