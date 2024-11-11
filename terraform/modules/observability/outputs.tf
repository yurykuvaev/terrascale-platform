output "loki_bucket_name" {
  description = "Loki S3 chunk bucket."
  value       = aws_s3_bucket.loki.bucket
}

output "loki_bucket_arn" {
  description = "ARN of the Loki S3 bucket."
  value       = aws_s3_bucket.loki.arn
}

output "loki_role_arn" {
  description = "IRSA role ARN for Loki."
  value       = module.loki_irsa.role_arn
}
