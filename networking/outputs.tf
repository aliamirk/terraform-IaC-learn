################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "default_security_group_id" {
  description = "The ID of the VPC's default security group."
  value       = aws_vpc.this.default_security_group_id
}

output "default_network_acl_id" {
  description = "The ID of the VPC's default network ACL."
  value       = aws_vpc.this.default_network_acl_id
}

output "default_route_table_id" {
  description = "The ID of the VPC's default route table."
  value       = aws_vpc.this.default_route_table_id
}

################################################################################
# Internet Gateway
################################################################################

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway (empty string if not created)."
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : ""
}

output "internet_gateway_arn" {
  description = "The ARN of the Internet Gateway (empty string if not created)."
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].arn : ""
}

################################################################################
# Public Subnets
################################################################################

output "public_subnet_ids" {
  description = "List of IDs of public subnets."
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets."
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of public subnets."
  value       = aws_subnet.public[*].cidr_block
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables."
  value       = aws_route_table.public[*].id
}

################################################################################
# Private Subnets
################################################################################

output "private_subnet_ids" {
  description = "List of IDs of private subnets."
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets."
  value       = aws_subnet.private[*].arn
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of private subnets."
  value       = aws_subnet.private[*].cidr_block
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables."
  value       = aws_route_table.private[*].id
}

################################################################################
# Database Subnets
################################################################################

output "database_subnet_ids" {
  description = "List of IDs of database subnets (empty list if not created)."
  value       = aws_subnet.database[*].id
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets."
  value       = aws_subnet.database[*].arn
}

output "database_subnet_cidr_blocks" {
  description = "List of CIDR blocks of database subnets."
  value       = aws_subnet.database[*].cidr_block
}

output "database_subnet_group_id" {
  description = "The ID of the database subnet group (empty string if not created)."
  value       = length(aws_db_subnet_group.this) > 0 ? aws_db_subnet_group.this[0].id : ""
}

output "database_subnet_group_arn" {
  description = "The ARN of the database subnet group (empty string if not created)."
  value       = length(aws_db_subnet_group.this) > 0 ? aws_db_subnet_group.this[0].arn : ""
}

output "database_route_table_ids" {
  description = "List of IDs of database route tables."
  value       = aws_route_table.database[*].id
}

################################################################################
# NAT Gateway
################################################################################

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs."
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IP addresses associated with NAT Gateways."
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_allocation_ids" {
  description = "List of Elastic IP allocation IDs used by NAT Gateways."
  value       = aws_eip.nat[*].id
}

################################################################################
# VPC Endpoints
################################################################################

output "s3_endpoint_id" {
  description = "The ID of the S3 Gateway VPC Endpoint (empty string if not created)."
  value       = length(aws_vpc_endpoint.s3) > 0 ? aws_vpc_endpoint.s3[0].id : ""
}

output "dynamodb_endpoint_id" {
  description = "The ID of the DynamoDB Gateway VPC Endpoint (empty string if not created)."
  value       = length(aws_vpc_endpoint.dynamodb) > 0 ? aws_vpc_endpoint.dynamodb[0].id : ""
}

################################################################################
# VPC Flow Logs
################################################################################

output "flow_log_id" {
  description = "The ID of the VPC Flow Log (empty string if not enabled)."
  value       = length(aws_flow_log.this) > 0 ? aws_flow_log.this[0].id : ""
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "The ARN of the auto-created CloudWatch log group for flow logs."
  value       = length(aws_cloudwatch_log_group.flow_log) > 0 ? aws_cloudwatch_log_group.flow_log[0].arn : ""
}
