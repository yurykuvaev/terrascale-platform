# AWS Load Balancer Controller IAM only.
#
# As of 2024-10 the chart itself is installed by ArgoCD from
# kubernetes/platform/<env>/aws-load-balancer-controller. This module owns
# only the AWS-side surface (IAM policy + IRSA role); the Helm release moved
# to GitOps so chart changes ride the normal review path.

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

  role_name         = "${var.cluster_name}-alb-controller"
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url
  namespace         = var.namespace
  service_account   = "aws-load-balancer-controller"
  policy_arns       = [aws_iam_policy.alb_controller.arn]
  tags              = var.tags
}

# Helm release for the ALB controller has moved to ArgoCD; see
# kubernetes/platform/<env>/aws-load-balancer-controller.
