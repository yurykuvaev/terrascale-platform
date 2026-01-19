include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "envcommon" {
  path = find_in_parent_folders("_envcommon/eks.hcl")
}

locals {
  env             = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  account         = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
  karpenter_node_role_name = "${local.env.cluster_name}-karpenter-node"
}

inputs = {
  cluster_name    = local.env.cluster_name
  cluster_version = "1.31"

  # Trust the role that Karpenter-provisioned nodes assume. The role itself is
  # created by the karpenter unit; we reference it by ARN so cluster apply
  # doesn't need to wait for karpenter (the role just needs to exist by the
  # time a node tries to register).
  access_entries = {
    karpenter_nodes = {
      principal_arn = "arn:aws:iam::${local.account.account_id}:role/${local.karpenter_node_role_name}"
      type          = "EC2_LINUX"
    }
  }

  # Public API endpoint is acceptable in dev. Tighten in staging/prod.
  endpoint_public_access       = true
  endpoint_public_access_cidrs = ["0.0.0.0/0"]

  managed_node_groups = {
    system = {
      desired_size = 2
      min_size     = 2
      max_size     = 4

      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"

      labels = {
        "workload-class" = "system"
      }

      taints = {
        system = {
          key    = "platform.terrascale.io/system"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }
}
