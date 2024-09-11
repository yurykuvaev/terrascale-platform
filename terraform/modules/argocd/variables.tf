variable "cluster_name" {
  description = "EKS cluster name (used to namespace IAM resources and tag the install)."
  type        = string
}

variable "namespace" {
  description = "Namespace ArgoCD is installed into."
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "argo-cd Helm chart version."
  type        = string
  default     = "7.4.0"
}

variable "ha" {
  description = "Run ArgoCD components in HA mode (multiple replicas, Redis HA). Recommended for staging and prod."
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Hostname to expose the ArgoCD UI on. Set to null to skip ingress."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to AWS-side resources."
  type        = map(string)
  default     = {}
}
