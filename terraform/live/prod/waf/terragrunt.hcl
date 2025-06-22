include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "${get_repo_root()}//terraform/modules/waf"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

inputs = {
  name                = "terrascale-${local.env.environment}"
  scope               = "REGIONAL"
  rate_limit_per_5min = 1000
}
