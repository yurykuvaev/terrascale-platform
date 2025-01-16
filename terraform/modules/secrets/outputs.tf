output "eso_role_arn" {
  description = "IRSA role ARN for ESO."
  value       = module.eso_irsa.role_arn
}

output "secrets_path_prefix" {
  description = "Secrets Manager path prefix ESO can read."
  value       = local.secrets_prefix
}

output "ssm_path_prefix" {
  description = "SSM Parameter Store path prefix ESO can read."
  value       = local.ssm_prefix
}
