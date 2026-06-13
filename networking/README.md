# networking

A professional, flexible Terraform module that provisions a fully-featured AWS network topology. Every aspect is configurable through input variables so the same module serves a single-AZ dev environment all the way up to a multi-AZ production setup.

---

## Features

| Feature | Details |
|---|---|
| **VPC** | Configurable CIDR, DNS support/hostnames |
| **Internet Gateway** | Optional, auto-wired to public route table |
| **Public subnets** | Any number, spread across supplied AZs |
| **Private subnets** | Any number; routed through NAT Gateway(s) |
| **Database subnets** | Optional isolated tier + RDS DB Subnet Group |
| **NAT Gateways** | Single shared *or* one-per-AZ HA; fully optional |
| **Route tables** | Separate RT per tier; auto-associated |
| **VPC Endpoints** | Free Gateway endpoints for S3 & DynamoDB |
| **VPC Flow Logs** | CloudWatch Logs *or* S3, with IAM role auto-created |
| **Default SG/NACL** | Locked down to prevent accidental exposure |
| **Tagging** | Global + per-resource override maps |

---

## Usage

```hcl
module "networking" {
  source = "./networking"

  name    = "my-app-prod"
  vpc_cidr = "10.0.0.0/16"

  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.4.0/22", "10.0.8.0/22", "10.0.12.0/22"]

  create_nat_gateway = true
  single_nat_gateway = false   # one NAT GW per AZ (HA)

  enable_flow_logs  = true
  create_s3_endpoint = true

  tags = {
    Project     = "my-app"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

See [`examples/complete/main.tf`](examples/complete/main.tf) for a full HA example and a minimal dev configuration.

---

## Requirements

| Tool | Version |
|---|---|
| Terraform | >= 1.3.0 |
| AWS Provider | >= 5.0 |

---

## Input Variables

### General

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | **required** | Prefix for all resource names |
| `tags` | `map(string)` | `{}` | Tags applied to every resource |

### VPC

| Name | Type | Default | Description |
|---|---|---|---|
| `vpc_cidr` | `string` | **required** | IPv4 CIDR for the VPC |
| `enable_dns_support` | `bool` | `true` | DNS resolution inside VPC |
| `enable_dns_hostnames` | `bool` | `true` | DNS hostnames on instances |
| `vpc_tags` | `map(string)` | `{}` | Extra tags for VPC only |

### Availability Zones

| Name | Type | Default | Description |
|---|---|---|---|
| `availability_zones` | `list(string)` | `[]` | AZs for subnet distribution; empty = AWS auto-assign |

### Internet Gateway

| Name | Type | Default | Description |
|---|---|---|---|
| `create_internet_gateway` | `bool` | `true` | Create an IGW |
| `internet_gateway_tags` | `map(string)` | `{}` | Extra tags for IGW |

### Public Subnets

| Name | Type | Default | Description |
|---|---|---|---|
| `public_subnet_cidrs` | `list(string)` | `[]` | One public subnet per entry |
| `map_public_ip_on_launch` | `bool` | `true` | Auto-assign public IPs |
| `public_subnet_tags` | `map(string)` | `{}` | Extra tags (e.g. K8s ELB annotations) |
| `public_route_table_tags` | `map(string)` | `{}` | Extra tags for public RT |

### Private Subnets

| Name | Type | Default | Description |
|---|---|---|---|
| `private_subnet_cidrs` | `list(string)` | `[]` | One private subnet per entry |
| `private_subnet_tags` | `map(string)` | `{}` | Extra tags |
| `private_route_table_tags` | `map(string)` | `{}` | Extra tags for private RT(s) |

### Database Subnets

| Name | Type | Default | Description |
|---|---|---|---|
| `database_subnet_cidrs` | `list(string)` | `[]` | Isolated DB tier (optional) |
| `create_database_subnet_group` | `bool` | `true` | Create RDS subnet group |
| `create_database_nat_gateway_route` | `bool` | `false` | Route DB tier through NAT |
| `create_database_internet_gateway_route` | `bool` | `false` | Route DB tier to IGW (**use with caution**) |
| `database_subnet_tags` | `map(string)` | `{}` | Extra tags |
| `database_subnet_group_tags` | `map(string)` | `{}` | Extra tags for subnet group |
| `database_route_table_tags` | `map(string)` | `{}` | Extra tags |

### NAT Gateway

| Name | Type | Default | Description |
|---|---|---|---|
| `create_nat_gateway` | `bool` | `true` | Provision NAT Gateway(s) |
| `single_nat_gateway` | `bool` | `false` | Share one NAT GW (cost-saving, lower HA) |
| `nat_gateway_tags` | `map(string)` | `{}` | Extra tags |
| `nat_eip_tags` | `map(string)` | `{}` | Extra tags for EIPs |

### VPC Flow Logs

| Name | Type | Default | Description |
|---|---|---|---|
| `enable_flow_logs` | `bool` | `false` | Enable VPC Flow Logs |
| `flow_log_traffic_type` | `string` | `"ALL"` | `ACCEPT`, `REJECT`, or `ALL` |
| `flow_log_destination_type` | `string` | `"cloud-watch-logs"` | `cloud-watch-logs` or `s3` |
| `flow_log_destination_arn` | `string` | `null` | Existing CWL group or S3 bucket ARN; `null` = auto-create |
| `flow_log_cloudwatch_log_group_retention_in_days` | `number` | `90` | Log retention days (`0` = never expire) |
| `flow_log_cloudwatch_log_group_kms_key_id` | `string` | `null` | KMS key ARN for log group encryption |
| `flow_log_file_format` | `string` | `"plain-text"` | `plain-text` or `parquet` (S3 only) |
| `flow_log_hive_compatible_partitions` | `bool` | `false` | Hive-style S3 partitions |
| `flow_log_per_hour_partition` | `bool` | `false` | Per-hour S3 partitions |

### VPC Endpoints

| Name | Type | Default | Description |
|---|---|---|---|
| `create_s3_endpoint` | `bool` | `false` | Gateway endpoint for S3 (free) |
| `create_dynamodb_endpoint` | `bool` | `false` | Gateway endpoint for DynamoDB (free) |

### Security Hardening

| Name | Type | Default | Description |
|---|---|---|---|
| `manage_default_security_group` | `bool` | `true` | Lock down the default SG |
| `manage_default_network_acl` | `bool` | `true` | Manage the default NACL |

---

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | VPC ID |
| `vpc_arn` | VPC ARN |
| `vpc_cidr_block` | VPC CIDR |
| `internet_gateway_id` | IGW ID |
| `public_subnet_ids` | List of public subnet IDs |
| `public_subnet_cidr_blocks` | List of public subnet CIDRs |
| `public_route_table_ids` | List of public RT IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `private_subnet_cidr_blocks` | List of private subnet CIDRs |
| `private_route_table_ids` | List of private RT IDs |
| `database_subnet_ids` | List of DB subnet IDs |
| `database_subnet_group_id` | RDS subnet group ID |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `nat_gateway_public_ips` | List of NAT EIP public IPs |
| `s3_endpoint_id` | S3 Gateway endpoint ID |
| `dynamodb_endpoint_id` | DynamoDB Gateway endpoint ID |
| `flow_log_id` | VPC Flow Log resource ID |
| `flow_log_cloudwatch_log_group_arn` | Auto-created CWL log group ARN |

---

## Architecture Diagrams

### High-Availability (production)

```
                          ┌─────────────────────────────────────────────────┐
                          │                      VPC                        │
 Internet                 │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
    │                     │  │  AZ - a  │  │  AZ - b  │  │  AZ - c  │      │
    ▼                     │  │          │  │          │  │          │      │
┌───────┐                 │  │ Public   │  │ Public   │  │ Public   │      │
│  IGW  │─────────────────┼─▶│ Subnet   │  │ Subnet   │  │ Subnet   │      │
└───────┘                 │  │          │  │          │  │          │      │
                          │  │ [NAT-a]  │  │ [NAT-b]  │  │ [NAT-c]  │      │
                          │  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
                          │       │              │              │            │
                          │  ┌────▼─────┐  ┌────▼─────┐  ┌────▼─────┐      │
                          │  │ Private  │  │ Private  │  │ Private  │      │
                          │  │ Subnet   │  │ Subnet   │  │ Subnet   │      │
                          │  └──────────┘  └──────────┘  └──────────┘      │
                          │                                                 │
                          │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
                          │  │ Database │  │ Database │  │ Database │      │
                          │  │ Subnet   │  │ Subnet   │  │ Subnet   │      │
                          │  └──────────┘  └──────────┘  └──────────┘      │
                          └─────────────────────────────────────────────────┘
```

### Cost-optimised (dev / staging) — `single_nat_gateway = true`

```
  IGW → Public Subnet (AZ-a, AZ-b, AZ-c)
           │
         [NAT] ← single shared NAT
           │
  Private Subnet (AZ-a, AZ-b, AZ-c) all share one route table
```

---

## Cost Considerations

- **NAT Gateway** is billed per hour + per GB processed. Use `single_nat_gateway = true` in non-prod to save ~$32/month per gateway eliminated.
- **S3 & DynamoDB Gateway endpoints** are free and should always be enabled; they bypass the NAT gateway and reduce data-processing charges.
- **VPC Flow Logs** to S3 with `parquet` format and per-hour partitions reduces Athena query costs significantly for high-traffic environments.

---

## License

MIT
