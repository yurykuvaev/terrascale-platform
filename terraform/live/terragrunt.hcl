# Root Terragrunt configuration.
#
# Every leaf `terragrunt.hcl` includes this file with `include "root" { path = find_in_parent_folders() }`.
# It centralises:
#   - Remote state (S3 + DynamoDB lock)
#   - The AWS provider, generated into each module so individual modules
#     don't need their own provider blocks.
#   - Default tags applied to every taggable resource.

locals {
  # Account / region pulled in by the leaf module via merge with env.hcl.
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  account_id   = local.account_vars.locals.account_id
  region       = local.env_vars.locals.region
  environment  = local.env_vars.locals.environment

  state_bucket = "terrascale-tfstate-${local.account_id}"
  lock_table   = "terrascale-tflock"
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = local.state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = local.lock_table
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"

  default_tags {
    tags = {
      Project     = "terrascale-platform"
      Environment = "${local.environment}"
      ManagedBy   = "Terragrunt"
      Repository  = "github.com/yurykuvaev/terrascale-platform"
    }
  }

  # Hard fail if the wrong account is targeted from the wrong env.
  allowed_account_ids = ["${local.account_id}"]
}
EOF
}

inputs = {
  environment = local.environment
  region      = local.region
}
