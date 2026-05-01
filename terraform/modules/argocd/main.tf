resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

# A randomly generated initial admin password is preferable to letting Argo
# generate one and storing the result in tfstate; we control rotation.
resource "random_password" "admin" {
  length  = 32
  special = false
}

resource "kubernetes_secret_v1" "admin_secret" {
  metadata {
    name      = "argocd-secret"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "argocd-secret"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  # bcrypt of the admin password. The chart consumes this on first install
  # and ignores it after, so rotation is a separate flow.
  data = {
    "admin.password"      = bcrypt(random_password.admin.result)
    "admin.passwordMtime" = "2024-09-10T22:14:00Z"
  }

  lifecycle {
    ignore_changes = [data]
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  values = [yamlencode({
    global = {
      domain = var.ingress_host
    }

    configs = {
      params = {
        # Argo's API server runs behind the ALB, which terminates TLS.
        "server.insecure" = true
      }
    }

    # Always pin platform charts to system nodes so they survive Karpenter churn.
    nodeSelector = { "workload-class" = "system" }
    tolerations = [{
      key      = "platform.terrascale.io/system"
      operator = "Equal"
      value    = "true"
      effect   = "NoSchedule"
    }]

    redis-ha       = { enabled = var.ha }
    controller     = var.ha ? { replicas = 2 } : {}
    server         = var.ha ? { replicas = 2, autoscaling = { enabled = true, minReplicas = 2, maxReplicas = 5 } } : {}
    repoServer     = var.ha ? { replicas = 2 } : {}
    applicationSet = var.ha ? { replicas = 2 } : {}
  })]

  depends_on = [kubernetes_secret_v1.admin_secret]
}
