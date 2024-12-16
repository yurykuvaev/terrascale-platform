terraform {
  source = "${get_repo_root()}//terraform/modules/observability"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    cluster_name      = "mock"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/example"
    oidc_provider_url = "oidc.eks.us-east-1.amazonaws.com/id/MOCK"
  }
}

inputs = {
  cluster_name      = dependency.eks.outputs.cluster_name
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url = dependency.eks.outputs.oidc_provider_url
}
