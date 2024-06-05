variable "cluster_name" {
  description = "EKS cluster name Karpenter manages."
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS API endpoint URL."
  type        = string
}

variable "oidc_provider_arn" {
  description = "Cluster OIDC provider ARN for IRSA."
  type        = string
}

variable "oidc_provider_url" {
  description = "Cluster OIDC provider URL (without https://)."
  type        = string
}

variable "node_iam_role_name" {
  description = <<-EOT
    Name of the IAM role Karpenter-provisioned nodes assume. The role must be
    listed in the cluster's access entries with the AmazonEKSAutoNodePolicy
    or equivalent.
  EOT
  type        = string
}

variable "interruption_queue_message_retention_seconds" {
  description = "How long Karpenter's SQS interruption queue retains messages."
  type        = number
  default     = 300
}

variable "chart_version" {
  description = "Karpenter Helm chart version."
  type        = string
  default     = "1.0.6"
}

variable "namespace" {
  description = "Kubernetes namespace Karpenter is installed into."
  type        = string
  default     = "karpenter"
}

variable "tags" {
  description = "Tags applied to AWS resources."
  type        = map(string)
  default     = {}
}
