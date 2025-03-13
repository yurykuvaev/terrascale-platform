output "plan_role_arn" {
  description = "ARN of the read-only plan role."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "ARN of the read-write apply role."
  value       = aws_iam_role.apply.arn
}

output "image_publish_role_arn" {
  description = "ARN of the image publish role."
  value       = aws_iam_role.image_publish.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}
