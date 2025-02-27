include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "envcommon" {
  path = find_in_parent_folders("_envcommon/secrets.hcl")
}

inputs = {
  namespace                 = "external-secrets"
  service_account           = "external-secrets"
  secrets_path_prefix       = "/terrascale-dev/"
  ssm_parameter_path_prefix = "/terrascale-dev/"
}
