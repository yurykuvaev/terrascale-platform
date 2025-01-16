variable "cluster_name" {
  description = "EKS cluster name (used for IAM resource names)."
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN."
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider URL (without https://)."
  type        = string
}

variable "namespace" {
  description = "Namespace ESO runs in."
  type        = string
  default     = "external-secrets"
}

variable "service_account" {
  description = "Service account ESO uses."
  type        = string
  default     = "external-secrets"
}

variable "secrets_path_prefix" {
  description = <<-EOT
    Secrets Manager path prefix this cluster's ESO is allowed to read.
    Defaults to /<cluster_name>/, which matches our convention of namespacing
    secrets per cluster.
  EOT
  type        = string
  default     = null
}

variable "ssm_parameter_path_prefix" {
  description = "SSM Parameter Store path prefix the cluster's ESO can read."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to AWS resources."
  type        = map(string)
  default     = {}
}
