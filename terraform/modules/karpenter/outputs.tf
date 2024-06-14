output "controller_role_arn" {
  description = "ARN of the Karpenter controller IRSA role."
  value       = aws_iam_role.controller.arn
}

output "interruption_queue_arn" {
  description = "ARN of the spot interruption SQS queue."
  value       = aws_sqs_queue.interruption.arn
}

output "interruption_queue_name" {
  description = "Name of the spot interruption SQS queue."
  value       = aws_sqs_queue.interruption.name
}

output "namespace" {
  description = "Namespace Karpenter runs in."
  value       = kubernetes_namespace_v1.karpenter.metadata[0].name
}

output "node_role_arn" {
  description = "ARN of the IAM role assumed by Karpenter-provisioned nodes."
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Name of the IAM role assumed by Karpenter-provisioned nodes."
  value       = aws_iam_role.node.name
}
