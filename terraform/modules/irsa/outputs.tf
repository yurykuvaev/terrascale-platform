output "role_arn" {
  description = "ARN of the IRSA role."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IRSA role."
  value       = aws_iam_role.this.name
}

output "service_account_annotation" {
  description = "Map suitable for spreading into a Kubernetes service account's annotations."
  value = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
  }
}
