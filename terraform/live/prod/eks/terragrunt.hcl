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
  cluster_version = "1.30"

  # Private API only in prod. Reach via VPN, bastion, or AWS Client VPN.
  endpoint_public_access       = false
  endpoint_public_access_cidrs = []

  # Three system nodes across three AZs. Larger instance type because the
  # observability stack lives here.
  managed_node_groups = {
    system = {
      desired_size   = 3
      min_size       = 3
      max_size       = 9
      instance_types = ["m6i.xlarge"]
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

  control_plane_log_retention_days = 90

  access_entries = {
    karpenter_nodes = {
      principal_arn = "arn:aws:iam::${local.account.account_id}:role/${local.karpenter_node_role_name}"
      type          = "EC2_LINUX"
    }

    # Break-glass admin: SSO group, not an individual.
    platform_admins = {
      principal_arn = "arn:aws:iam::${local.account.account_id}:role/AWSReservedSSO_PlatformAdmin"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }
}
