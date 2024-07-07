# AWS Load Balancer Controller — provisions ALBs and NLBs from Ingress and
# Service objects. The IAM permission set below is taken from the upstream
# install guide; we keep it here rather than using a managed policy because
# the upstream policy is published as JSON, not as an AWS-managed policy ARN.

resource "kubernetes_namespace_v1" "ingress" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = "baseline"
    }
  }
}

# Pull the upstream IAM policy document. Updated periodically; bumping
# requires re-fetching from
# https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
data "http" "alb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.8.1/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-alb-controller"
  description = "AWS Load Balancer Controller permissions for ${var.cluster_name}"
  policy      = data.http.alb_policy.response_body
  tags        = var.tags
}

module "alb_controller_irsa" {
  source = "../irsa"

  role_name          = "${var.cluster_name}-alb-controller"
  oidc_provider_arn  = var.oidc_provider_arn
  oidc_provider_url  = var.oidc_provider_url
  namespace          = var.namespace
  service_account    = "aws-load-balancer-controller"
  policy_arns        = [aws_iam_policy.alb_controller.arn]
  tags               = var.tags
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.alb_chart_version
  namespace  = kubernetes_namespace_v1.ingress.metadata[0].name

  values = [yamlencode({
    clusterName = var.cluster_name
    region      = var.region
    vpcId       = var.vpc_id

    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
      annotations = module.alb_controller_irsa.service_account_annotation
    }

    nodeSelector = { "workload-class" = "system" }
    tolerations = [{
      key      = "platform.terrascale.io/system"
      operator = "Equal"
      value    = "true"
      effect   = "NoSchedule"
    }]

    resources = {
      requests = { cpu = "100m", memory = "128Mi" }
      limits   = { memory = "256Mi" }
    }
  })]
}
