################################################################################
# Example: Full HA setup — 3 public + 3 private + 3 database subnets,
#          one NAT Gateway per AZ, VPC Flow Logs to CloudWatch, S3 endpoint.
################################################################################

module "networking" {
  source = "./networking"

  # ── Identity ────────────────────────────────────────────────────────────────
  name = "my-app-prod"

  tags = {
    Project     = "my-app"
    Environment = "production"
    ManagedBy   = "terraform"
  }

  # ── VPC ─────────────────────────────────────────────────────────────────────
  vpc_cidr             = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  # ── AZs ─────────────────────────────────────────────────────────────────────
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # ── Public subnets (/24 each) ────────────────────────────────────────────────
  public_subnet_cidrs     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  map_public_ip_on_launch = true
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  # ── Private subnets (/22 each) ───────────────────────────────────────────────
  private_subnet_cidrs = ["10.0.4.0/22", "10.0.8.0/22", "10.0.12.0/22"]
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  # ── Database subnets (isolated, no route to NAT) ─────────────────────────────
  database_subnet_cidrs             = ["10.0.16.0/24", "10.0.17.0/24", "10.0.18.0/24"]
  create_database_subnet_group      = true
  create_database_nat_gateway_route = false

  # ── NAT Gateways (one per AZ for high availability) ─────────────────────────
  create_nat_gateway = true
  single_nat_gateway = false   # set true to save cost in non-prod

  # ── VPC Endpoints (Gateway type — free) ─────────────────────────────────────
  create_s3_endpoint       = true
  create_dynamodb_endpoint = true

  # ── VPC Flow Logs ────────────────────────────────────────────────────────────
  enable_flow_logs                                = true
  flow_log_destination_type                       = "cloud-watch-logs"
  flow_log_traffic_type                           = "ALL"
  flow_log_cloudwatch_log_group_retention_in_days = 90

  # ── Security hardening ───────────────────────────────────────────────────────
  manage_default_security_group = true
  manage_default_network_acl    = true
}

################################################################################
# Outputs (reference these in other modules / root)
################################################################################

output "vpc_id"             { value = module.networking.vpc_id }
output "public_subnet_ids"  { value = module.networking.public_subnet_ids }
output "private_subnet_ids" { value = module.networking.private_subnet_ids }
output "database_subnet_ids"{ value = module.networking.database_subnet_ids }
output "nat_gateway_ips"    { value = module.networking.nat_gateway_public_ips }


################################################################################
# Example: Minimal / single-AZ dev environment
################################################################################

# module "networking_dev" {
#   source = "./networking"
#
#   name     = "my-app-dev"
#   vpc_cidr = "10.1.0.0/16"
#
#   availability_zones   = ["us-east-1a"]
#   public_subnet_cidrs  = ["10.1.0.0/24"]
#   private_subnet_cidrs = ["10.1.1.0/24"]
#
#   create_nat_gateway = true
#   single_nat_gateway = true   # one NAT GW shared — saves ~$32/mo
#
#   enable_flow_logs = false     # skip logs in dev
#
#   tags = { Environment = "dev" }
# }
