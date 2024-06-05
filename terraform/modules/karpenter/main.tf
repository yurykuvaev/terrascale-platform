resource "kubernetes_namespace_v1" "karpenter" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by"        = "terraform"
      "pod-security.kubernetes.io/enforce"  = "restricted"
      "pod-security.kubernetes.io/audit"    = "restricted"
      "pod-security.kubernetes.io/warn"     = "restricted"
    }
  }
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.karpenter.metadata[0].name

  values = [yamlencode({
    settings = {
      clusterName       = var.cluster_name
      clusterEndpoint   = var.cluster_endpoint
      interruptionQueue = aws_sqs_queue.interruption.name
    }
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.controller.arn
      }
    }
    controller = {
      resources = {
        requests = { cpu = "200m", memory = "256Mi" }
        limits   = { memory = "512Mi" }
      }
    }
    # Karpenter must run on the system node group, not on a node it provisioned
    # itself. Otherwise consolidation can evict the controller and deadlock.
    tolerations = [{
      key      = "platform.terrascale.io/system"
      operator = "Equal"
      value    = "true"
      effect   = "NoSchedule"
    }]
    nodeSelector = {
      "workload-class" = "system"
    }
  })]

  depends_on = [
    aws_iam_role_policy_attachment.controller,
    aws_sqs_queue_policy.interruption,
  ]
}
