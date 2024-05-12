locals {
  module_version = "v0.1.0"

  # Pin the Kubernetes minor version per environment so upgrades are explicit.
  default_cluster_version = "1.30"
}

terraform {
  source = "${get_repo_root()}//terraform/modules/eks"
}

dependency "network" {
  config_path = "../network"

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-a", "subnet-b", "subnet-c"]
    intra_subnet_ids   = ["subnet-x", "subnet-y", "subnet-z"]
  }
}

inputs = {
  vpc_id                   = dependency.network.outputs.vpc_id
  subnet_ids               = dependency.network.outputs.private_subnet_ids
  control_plane_subnet_ids = dependency.network.outputs.intra_subnet_ids

  encrypt_secrets = true

  control_plane_log_types          = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  control_plane_log_retention_days = 30
}
