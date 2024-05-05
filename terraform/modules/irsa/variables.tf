variable "role_name" {
  description = "IAM role name for the service account."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider."
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the cluster's IAM OIDC provider (without the https:// prefix)."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace the service account lives in."
  type        = string
}

variable "service_account" {
  description = "Kubernetes service account name."
  type        = string
}

variable "policy_arns" {
  description = "List of managed policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional inline policy JSON document. Pass null to skip."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to the IAM role."
  type        = map(string)
  default     = {}
}
