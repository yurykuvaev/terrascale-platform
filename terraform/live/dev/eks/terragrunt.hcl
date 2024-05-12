include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "envcommon" {
  path = find_in_parent_folders("_envcommon/eks.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

inputs = {
  cluster_name    = local.env.cluster_name
  cluster_version = "1.30"

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
