locals {
  secrets_prefix = coalesce(var.secrets_path_prefix, "/${var.cluster_name}/")
  ssm_prefix     = coalesce(var.ssm_parameter_path_prefix, "/${var.cluster_name}/")

  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "eso" {
  statement {
    sid = "ReadSecretsManagerScoped"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [
      "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${trimprefix(local.secrets_prefix, "/")}*",
    ]
  }

  statement {
    sid       = "ListSecretsManager"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

  statement {
    sid     = "ReadSSMScoped"
    actions = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = [
      "arn:aws:ssm:${local.region}:${local.account_id}:parameter${local.ssm_prefix}*",
    ]
  }
}

resource "aws_iam_policy" "eso" {
  name   = "${var.cluster_name}-external-secrets"
  policy = data.aws_iam_policy_document.eso.json
  tags   = var.tags
}

module "eso_irsa" {
  source = "../irsa"

  role_name         = "${var.cluster_name}-external-secrets"
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url
  namespace         = var.namespace
  service_account   = var.service_account
  policy_arns       = [aws_iam_policy.eso.arn]
  tags              = var.tags
}
