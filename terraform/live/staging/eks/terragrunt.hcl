include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "envcommon" {
  path = find_in_parent_folders("_envcommon/eks.hcl")
}

locals {
  env                      = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  account                  = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
  karpenter_node_role_name = "${local.env.cluster_name}-karpenter-node"
}

inputs = {
  cluster_name    = local.env.cluster_name
  cluster_version = "1.31"

  # Lock the public endpoint to a CI egress range; CI plans/applies via OIDC,
  # human access goes through VPN.
  endpoint_public_access       = true
  endpoint_public_access_cidrs = ["140.82.112.0/20"]   # GitHub-hosted runners (placeholder; refine with own egress)

  managed_node_groups = {
    system = {
      desired_size   = 3
      min_size       = 3
      max_size       = 6
      instance_types = ["m6i.large"]
      capacity_type  = "ON_DEMAND"

      labels = { "workload-class" = "system" }
      taints = {
        system = {
          key    = "platform.terrascale.io/system"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  access_entries = {
    karpenter_nodes = {
      principal_arn = "arn:aws:iam::${local.account.account_id}:role/${local.karpenter_node_role_name}"
      type          = "EC2_LINUX"
    }
  }
}
