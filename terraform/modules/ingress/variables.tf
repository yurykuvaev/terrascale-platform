variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the cluster lives in (required by AWS Load Balancer Controller)."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "oidc_provider_arn" {
  description = "Cluster OIDC provider ARN."
  type        = string
}

variable "oidc_provider_url" {
  description = "Cluster OIDC provider URL (without https://)."
  type        = string
}

variable "namespace" {
  description = "Namespace for ingress controllers."
  type        = string
  default     = "ingress-system"
}

variable "alb_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version."
  type        = string
  default     = "1.8.1"
}

variable "tags" {
  description = "Tags for AWS resources."
  type        = map(string)
  default     = {}
}
