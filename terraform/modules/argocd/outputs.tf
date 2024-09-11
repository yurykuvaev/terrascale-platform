output "namespace" {
  description = "Namespace ArgoCD runs in."
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "admin_password" {
  description = "Initial ArgoCD admin password. Rotate via the UI after first login."
  value       = random_password.admin.result
  sensitive   = true
}
