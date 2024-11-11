variable "cluster_name" {
  description = "EKS cluster name (used for IAM names and the bucket)."
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA."
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider URL (without https://)."
  type        = string
}

variable "loki_namespace" {
  description = "Namespace Loki runs in."
  type        = string
  default     = "observability"
}

variable "loki_service_account" {
  description = "Service account name Loki uses."
  type        = string
  default     = "loki"
}

variable "loki_chunk_retention_days" {
  description = "How long Loki keeps log chunks in S3."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to AWS resources."
  type        = map(string)
  default     = {}
}
