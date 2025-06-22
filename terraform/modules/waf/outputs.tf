output "web_acl_arn" {
  description = "ARN of the WAFv2 WebACL. Reference from ALB ingress annotations."
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_id" {
  description = "ID of the WAFv2 WebACL."
  value       = aws_wafv2_web_acl.this.id
}
