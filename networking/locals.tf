################################################################################
# Local computed values
################################################################################

locals {
  # ---------------------------------------------------------------------------
  # NAT Gateway count
  # single_nat_gateway = true  → 1 NAT GW in the first public subnet
  # single_nat_gateway = false → 1 NAT GW per public subnet (one per AZ, HA)
  # ---------------------------------------------------------------------------
  nat_gateway_count = (
    !var.create_nat_gateway || length(var.public_subnet_cidrs) == 0
    ? 0
    : var.single_nat_gateway
    ? 1
    : length(var.public_subnet_cidrs)
  )

  # Index of the public subnet each NAT GW should live in
  nat_gateway_subnet_indices = [for i in range(local.nat_gateway_count) : i]

  # ---------------------------------------------------------------------------
  # Private route table count
  # One shared RT when single NAT or no NAT; one-per-AZ otherwise.
  # ---------------------------------------------------------------------------
  private_route_table_count = (
    length(var.private_subnet_cidrs) == 0
    ? 0
    : local.nat_gateway_count == 0 || var.single_nat_gateway
    ? 1
    : local.nat_gateway_count
  )

  # ---------------------------------------------------------------------------
  # Database route table count
  # ---------------------------------------------------------------------------
  database_route_table_count = (
    length(var.database_subnet_cidrs) == 0
    ? 0
    : var.create_database_nat_gateway_route && local.nat_gateway_count > 1
    ? local.nat_gateway_count
    : 1
  )

  # ---------------------------------------------------------------------------
  # Per-subnet database route table index
  # Returns 0 when there is only one database RT.
  # Returns the AZ-matched NAT GW index when we have per-AZ database RTs.
  # ---------------------------------------------------------------------------
  database_rt_index = (
    local.database_route_table_count <= 1
    ? [for i in range(length(var.database_subnet_cidrs)) : 0]
    : [for i in range(length(var.database_subnet_cidrs)) : i % local.database_route_table_count]
  )
}
