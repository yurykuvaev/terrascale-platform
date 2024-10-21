include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "envcommon" {
  path = find_in_parent_folders("_envcommon/argocd.hcl")
}

inputs = {
  ha            = false
  chart_version = "7.4.0"
  ingress_host  = "argocd.dev.example.com"
}
