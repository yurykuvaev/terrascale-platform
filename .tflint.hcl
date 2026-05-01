config {
  format           = "compact"
  call_module_type = "local"  # don't require remote modules to be initialised in CI
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Module wrappers don't need a complete set of provider/required_providers
# blocks at every leaf — we generate provider blocks via Terragrunt.
rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags    = ["Project", "Environment", "ManagedBy"]
}
