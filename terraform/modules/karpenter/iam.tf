# Controller role assumed via IRSA. The community-maintained
# terraform-aws-modules/eks/aws//modules/karpenter sub-module already wires
# this; we inline it here so we keep ownership of the policy surface and can
# audit / tighten it over time.

data "aws_iam_policy_document" "controller_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:karpenter"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "controller" {
  name               = "${var.cluster_name}-karpenter"
  assume_role_policy = data.aws_iam_policy_document.controller_assume.json
  tags               = var.tags
}

# Trimmed-down Karpenter controller policy. Mirrors the upstream
# CloudFormation template at karpenter.sh/v1.0/getting-started/.
data "aws_iam_policy_document" "controller" {
  statement {
    sid = "AllowScopedEC2InstanceActions"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowScopedEC2InstanceTagging"
    actions = [
      "ec2:CreateTags",
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  statement {
    sid       = "AllowEC2Read"
    actions   = ["ec2:Describe*", "pricing:GetProducts", "ssm:GetParameter"]
    resources = ["*"]
  }

  statement {
    sid       = "AllowPassNodeRole"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::*:role/${var.node_iam_role_name}"]
  }

  statement {
    sid       = "AllowInstanceProfileManagement"
    actions   = ["iam:AddRoleToInstanceProfile", "iam:CreateInstanceProfile", "iam:RemoveRoleFromInstanceProfile", "iam:DeleteInstanceProfile", "iam:GetInstanceProfile", "iam:TagInstanceProfile"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowInterruptionQueueActions"
    actions = ["sqs:DeleteMessage", "sqs:GetQueueUrl", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
    resources = [aws_sqs_queue.interruption.arn]
  }

  statement {
    sid       = "AllowReadEKS"
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:aws:eks:*:*:cluster/${var.cluster_name}"]
  }
}

resource "aws_iam_policy" "controller" {
  name   = "${var.cluster_name}-karpenter"
  policy = data.aws_iam_policy_document.controller.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "controller" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.controller.arn
}
