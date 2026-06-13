################################################################################
# General
################################################################################

variable "name" {
  description = "Prefix applied to all resource names for identification and tagging."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# VPC
################################################################################

variable "vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC (e.g. \"10.0.0.0/16\")."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "enable_dns_support" {
  description = "Enable DNS resolution support within the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostname assignment to instances launched in the VPC."
  type        = bool
  default     = true
}

variable "vpc_tags" {
  description = "Additional tags for the VPC resource only."
  type        = map(string)
  default     = {}
}

################################################################################
# Availability Zones
################################################################################

variable "availability_zones" {
  description = "List of AZs to distribute subnets across. If empty, AWS picks the AZ automatically."
  type        = list(string)
  default     = []
}

################################################################################
# Internet Gateway
################################################################################

variable "create_internet_gateway" {
  description = "Create an Internet Gateway. Set to false only when all workloads are fully private."
  type        = bool
  default     = true
}

variable "internet_gateway_tags" {
  description = "Additional tags for the Internet Gateway."
  type        = map(string)
  default     = {}
}

################################################################################
# Public Subnets
################################################################################

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets. One subnet is created per entry."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.public_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "All public_subnet_cidrs entries must be valid IPv4 CIDR blocks."
  }
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign a public IPv4 address to instances launched in public subnets."
  type        = bool
  default     = true
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets (e.g. Kubernetes ELB annotations)."
  type        = map(string)
  default     = {}
}

variable "public_route_table_tags" {
  description = "Additional tags for the public route table."
  type        = map(string)
  default     = {}
}

################################################################################
# Private Subnets
################################################################################

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets. One subnet is created per entry."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.private_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "All private_subnet_cidrs entries must be valid IPv4 CIDR blocks."
  }
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets (e.g. Kubernetes internal-ELB annotations)."
  type        = map(string)
  default     = {}
}

variable "private_route_table_tags" {
  description = "Additional tags for private route tables."
  type        = map(string)
  default     = {}
}

################################################################################
# Database Subnets (optional isolated tier)
################################################################################

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for a dedicated database subnet tier. Leave empty to skip."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.database_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "All database_subnet_cidrs entries must be valid IPv4 CIDR blocks."
  }
}

variable "create_database_subnet_group" {
  description = "Create an RDS DB subnet group from the database subnets."
  type        = bool
  default     = true
}

variable "create_database_nat_gateway_route" {
  description = "Add a default route in the database route table pointing to the NAT Gateway."
  type        = bool
  default     = false
}

variable "create_database_internet_gateway_route" {
  description = "Add a default route in the database route table pointing to the Internet Gateway (makes DB subnets public — use with caution)."
  type        = bool
  default     = false
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets."
  type        = map(string)
  default     = {}
}

variable "database_subnet_group_tags" {
  description = "Additional tags for the DB subnet group."
  type        = map(string)
  default     = {}
}

variable "database_route_table_tags" {
  description = "Additional tags for database route tables."
  type        = map(string)
  default     = {}
}

################################################################################
# NAT Gateway
################################################################################

variable "create_nat_gateway" {
  description = "Provision NAT Gateway(s) for private subnet egress. Requires at least one public subnet."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway shared by all private subnets (cheaper, lower HA). When false, one NAT Gateway is created per AZ."
  type        = bool
  default     = false
}

variable "nat_gateway_tags" {
  description = "Additional tags for NAT Gateways."
  type        = map(string)
  default     = {}
}

variable "nat_eip_tags" {
  description = "Additional tags for the Elastic IPs allocated to NAT Gateways."
  type        = map(string)
  default     = {}
}

################################################################################
# VPC Flow Logs
################################################################################

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs."
  type        = bool
  default     = false
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to capture: ACCEPT, REJECT, or ALL."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "flow_log_traffic_type must be one of: ACCEPT, REJECT, ALL."
  }
}

variable "flow_log_destination_type" {
  description = "Destination backend for flow logs: \"cloud-watch-logs\" or \"s3\"."
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log_destination_type)
    error_message = "flow_log_destination_type must be \"cloud-watch-logs\" or \"s3\"."
  }
}

variable "flow_log_destination_arn" {
  description = "ARN of an existing CloudWatch log group or S3 bucket to deliver flow logs. Leave null to create a new CloudWatch log group automatically."
  type        = string
  default     = null
}

variable "flow_log_cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain flow log events in the auto-created CloudWatch log group. 0 = never expire."
  type        = number
  default     = 90
}

variable "flow_log_cloudwatch_log_group_kms_key_id" {
  description = "KMS key ARN to encrypt the auto-created CloudWatch log group."
  type        = string
  default     = null
}

variable "flow_log_file_format" {
  description = "Log file format when destination type is s3: plain-text or parquet."
  type        = string
  default     = "plain-text"
}

variable "flow_log_hive_compatible_partitions" {
  description = "Use Hive-compatible S3 prefixes for flow log partitions."
  type        = bool
  default     = false
}

variable "flow_log_per_hour_partition" {
  description = "Partition S3 flow log files per hour instead of per day."
  type        = bool
  default     = false
}

variable "flow_log_tags" {
  description = "Additional tags for the VPC Flow Log resource."
  type        = map(string)
  default     = {}
}

################################################################################
# VPC Endpoints
################################################################################

variable "create_s3_endpoint" {
  description = "Create a Gateway VPC Endpoint for S3 (free, reduces NAT costs)."
  type        = bool
  default     = false
}

variable "create_dynamodb_endpoint" {
  description = "Create a Gateway VPC Endpoint for DynamoDB (free, reduces NAT costs)."
  type        = bool
  default     = false
}

################################################################################
# Default Security Group / Network ACL lockdown
################################################################################

variable "manage_default_security_group" {
  description = "Take ownership of the VPC default security group and remove all inbound/outbound rules."
  type        = bool
  default     = true
}

variable "manage_default_network_acl" {
  description = "Take ownership of the VPC default Network ACL and set sensible rules."
  type        = bool
  default     = true
}
