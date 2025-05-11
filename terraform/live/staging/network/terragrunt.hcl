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

  # Per-AZ NAT for staging — closer to prod, exposes any single-AZ assumptions.
  single_nat_gateway = false
}
