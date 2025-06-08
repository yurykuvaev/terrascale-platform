include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "envcommon" {
  path = find_in_parent_folders("_envcommon/network.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

inputs = {
  name                 = "terrascale-${local.env.environment}"
  cidr_block           = local.env.vpc_cidr
  azs                  = local.env.azs
  public_subnet_cidrs  = local.env.public_subnet_cidrs
  private_subnet_cidrs = local.env.private_subnet_cidrs
  intra_subnet_cidrs   = local.env.intra_subnet_cidrs
  cluster_name         = local.env.cluster_name

  # Always per-AZ NAT in prod — single NAT is a single AZ failure domain.
  single_nat_gateway = false

  # Long retention for forensics.
  flow_logs_retention_days = 90
}
