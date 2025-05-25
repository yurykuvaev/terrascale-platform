include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "envcommon" {
  path = find_in_parent_folders("_envcommon/observability.hcl")
}

inputs = {
  loki_namespace            = "observability"
  loki_service_account      = "loki"
  loki_chunk_retention_days = 90
}
