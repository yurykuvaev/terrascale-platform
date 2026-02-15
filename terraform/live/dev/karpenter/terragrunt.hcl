include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "envcommon" {
  path = find_in_parent_folders("_envcommon/karpenter.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

inputs = {
  node_iam_role_name = "${local.env.cluster_name}-karpenter-node"
  chart_version      = "1.0.8"
}
