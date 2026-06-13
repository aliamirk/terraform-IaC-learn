################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    var.tags,
    { Name = "${var.name}-vpc" },
    var.vpc_tags
  )
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count = var.create_internet_gateway && length(var.public_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    { Name = "${var.name}-igw" },
    var.internet_gateway_tags
  )
}

################################################################################
# Public Subnets
################################################################################

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : null
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-subnet-${count.index + 1}"
      Tier = "public"
    },
    var.public_subnet_tags
  )
}

################################################################################
# Private Subnets
################################################################################

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : null

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-subnet-${count.index + 1}"
      Tier = "private"
    },
    var.private_subnet_tags
  )
}

################################################################################
# Database Subnets (optional)
################################################################################

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : null

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-db-subnet-${count.index + 1}"
      Tier = "database"
    },
    var.database_subnet_tags
  )
}

resource "aws_db_subnet_group" "this" {
  count = var.create_database_subnet_group && length(var.database_subnet_cidrs) > 0 ? 1 : 0

  name        = "${var.name}-db-subnet-group"
  description = "Database subnet group for ${var.name}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(
    var.tags,
    { Name = "${var.name}-db-subnet-group" },
    var.database_subnet_group_tags
  )
}

################################################################################
# Elastic IPs for NAT Gateways
################################################################################

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(
    var.tags,
    { Name = "${var.name}-nat-eip-${count.index + 1}" },
    var.nat_eip_tags
  )

  depends_on = [aws_internet_gateway.this]
}

################################################################################
# NAT Gateway
################################################################################

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[local.nat_gateway_subnet_indices[count.index]].id

  tags = merge(
    var.tags,
    { Name = "${var.name}-nat-gw-${count.index + 1}" },
    var.nat_gateway_tags
  )

  depends_on = [aws_internet_gateway.this]
}

################################################################################
# Public Route Table
################################################################################

resource "aws_route_table" "public" {
  count = length(var.public_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    { Name = "${var.name}-public-rt" },
    var.public_route_table_tags
  )
}

resource "aws_route" "public_internet_gateway" {
  count = length(var.public_subnet_cidrs) > 0 && var.create_internet_gateway ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

################################################################################
# Private Route Tables
################################################################################

resource "aws_route_table" "private" {
  count = local.private_route_table_count

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = var.single_nat_gateway ? "${var.name}-private-rt" : "${var.name}-private-rt-${count.index + 1}"
    },
    var.private_route_table_tags
  )
}

resource "aws_route" "private_nat_gateway" {
  count = var.create_nat_gateway && length(var.private_subnet_cidrs) > 0 ? local.nat_gateway_count : 0

  route_table_id         = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index % local.nat_gateway_count].id
}

################################################################################
# Database Route Tables
################################################################################

resource "aws_route_table" "database" {
  count = local.database_route_table_count

  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = var.create_database_nat_gateway_route ? "${var.name}-db-rt-${count.index + 1}" : "${var.name}-db-rt"
    },
    var.database_route_table_tags
  )
}

resource "aws_route" "database_nat_gateway" {
  count = var.create_database_nat_gateway_route && var.create_nat_gateway && length(var.database_subnet_cidrs) > 0 ? local.nat_gateway_count : 0

  route_table_id         = aws_route_table.database[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "database_internet_gateway" {
  count = var.create_database_internet_gateway_route && var.create_internet_gateway && length(var.database_subnet_cidrs) > 0 ? 1 : 0

  route_table_id         = aws_route_table.database[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[local.database_rt_index[count.index]].id
}

################################################################################
# VPC Flow Logs
################################################################################

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id          = aws_vpc.this.id
  traffic_type    = var.flow_log_traffic_type
  iam_role_arn    = var.flow_log_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_log[0].arn : null
  log_destination = var.flow_log_destination_arn

  dynamic "destination_options" {
    for_each = var.flow_log_destination_type == "s3" ? [1] : []
    content {
      file_format                = var.flow_log_file_format
      hive_compatible_partitions = var.flow_log_hive_compatible_partitions
      per_hour_partition         = var.flow_log_per_hour_partition
    }
  }

  tags = merge(
    var.tags,
    { Name = "${var.name}-flow-log" },
    var.flow_log_tags
  )
}

resource "aws_cloudwatch_log_group" "flow_log" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" && var.flow_log_destination_arn == null ? 1 : 0

  name              = "/aws/vpc-flow-log/${var.name}"
  retention_in_days = var.flow_log_cloudwatch_log_group_retention_in_days
  kms_key_id        = var.flow_log_cloudwatch_log_group_kms_key_id

  tags = merge(
    var.tags,
    { Name = "${var.name}-flow-log-group" }
  )
}

resource "aws_iam_role" "flow_log" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name               = "${var.name}-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume_role[0].json

  tags = merge(
    var.tags,
    { Name = "${var.name}-flow-log-role" }
  )
}

resource "aws_iam_role_policy" "flow_log" {
  count = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name   = "${var.name}-flow-log-policy"
  role   = aws_iam_role.flow_log[0].id
  policy = data.aws_iam_policy_document.flow_log[0].json
}

################################################################################
# VPC Endpoints (optional)
################################################################################

resource "aws_vpc_endpoint" "s3" {
  count = var.create_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(aws_route_table.private[*].id, aws_route_table.public[*].id)

  tags = merge(
    var.tags,
    { Name = "${var.name}-s3-endpoint" }
  )
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.create_dynamodb_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(aws_route_table.private[*].id, aws_route_table.public[*].id)

  tags = merge(
    var.tags,
    { Name = "${var.name}-dynamodb-endpoint" }
  )
}

################################################################################
# Default Security Group (lockdown)
################################################################################

resource "aws_default_security_group" "this" {
  count = var.manage_default_security_group ? 1 : 0

  vpc_id = aws_vpc.this.id

  ingress = []
  egress  = []

  tags = merge(
    var.tags,
    { Name = "${var.name}-default-sg" }
  )
}

################################################################################
# Default Network ACL (lockdown)
################################################################################

resource "aws_default_network_acl" "this" {
  count = var.manage_default_network_acl ? 1 : 0

  default_network_acl_id = aws_vpc.this.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.this.cidr_block
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.tags,
    { Name = "${var.name}-default-nacl" }
  )
}
