output "namespace" {
  description = "Namespace ingress controllers run in."
  value       = kubernetes_namespace_v1.ingress.metadata[0].name
}

output "alb_controller_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller."
  value       = module.alb_controller_irsa.role_arn
}
