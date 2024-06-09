# Default NodeClass and NodePool. Application workloads scheduled without an
# explicit nodeSelector / affinity match this pool by default.
#
# We deliberately avoid baking workload-specific node pools into this module:
# additional pools belong in the GitOps tree so platform tenants can request
# them without a Terraform PR.

resource "kubernetes_manifest" "default_nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "AL2023"
      amiSelectorTerms = [
        { alias = "al2023@latest" },
      ]
      role = var.node_iam_role_name
      subnetSelectorTerms = [
        { tags = { "karpenter.sh/discovery" = var.cluster_name } },
      ]
      securityGroupSelectorTerms = [
        { tags = { "karpenter.sh/discovery" = var.cluster_name } },
      ]
      blockDeviceMappings = [{
        deviceName = "/dev/xvda"
        ebs = {
          volumeSize = "100Gi"
          volumeType = "gp3"
          encrypted  = true
          deleteOnTermination = true
        }
      }]
      tags = merge(var.tags, {
        "karpenter.sh/discovery" = var.cluster_name
        "Name"                   = "${var.cluster_name}-karpenter"
      })
      metadataOptions = {
        # IMDSv2 only; one hop limit prevents pods reaching the metadata service.
        httpEndpoint            = "enabled"
        httpProtocolIPv6        = "disabled"
        httpPutResponseHopLimit = 1
        httpTokens              = "required"
      }
    }
  }

  depends_on = [helm_release.karpenter]
}

resource "kubernetes_manifest" "default_nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "workload-class" = "application"
          }
        }
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "default"
          }
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = ["linux"]
            },
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = ["c", "m", "r"]
            },
            {
              key      = "karpenter.k8s.aws/instance-generation"
              operator = "Gt"
              values   = ["3"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand", "spot"]
            },
          ]
          expireAfter = "720h"  # 30 days, then nodes are gracefully replaced
        }
      }
      limits = {
        cpu    = "1000"
        memory = "1000Gi"
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "30s"
        budgets = [{
          nodes = "10%"
        }]
      }
    }
  }

  depends_on = [kubernetes_manifest.default_nodeclass]
}
