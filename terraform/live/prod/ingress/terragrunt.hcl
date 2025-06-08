include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "envcommon" {
  path = find_in_parent_folders("_envcommon/ingress.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

inputs = {
  region = local.env.region

  external_dns_zone_id_filters = ["Z0123456789PRODUCTION"]
  external_dns_domain_filters  = ["example.com"]

  letsencrypt_email = "platform@example.com"
}
