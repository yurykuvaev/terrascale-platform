# Shared inputs and source pin for the network module across environments.
# Each env's terragrunt.hcl includes this and supplies env-specific CIDRs.

locals {
  module_version = "v0.1.0"
}

terraform {
  source = "${get_repo_root()}//terraform/modules/network"
}

inputs = {
  # Sensible defaults; env-specific overrides come from env.hcl.
  enable_vpc_endpoints       = true
  enable_flow_logs           = true
  flow_logs_destination_type = "cloud-watch-logs"
  flow_logs_retention_days   = 30
}
