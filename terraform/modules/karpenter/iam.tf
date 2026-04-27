# Inlined controller IRSA so we own the policy surface.

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
  # Launches are scoped by cluster tag — nothing without the discovery tag is
  # in scope for this role to mutate, even though the resource ARN must be *.
  statement {
    sid = "AllowScopedEC2InstanceActions"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/karpenter.sh/cluster"
      values   = [var.cluster_name]
    }
  }

  statement {
    sid       = "AllowLaunchTemplateCreate"
    actions   = ["ec2:CreateLaunchTemplate"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/karpenter.sh/cluster"
      values   = [var.cluster_name]
    }
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
      variable = "ec2:ResourceTag/karpenter.sh/cluster"
      values   = [var.cluster_name]
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
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  # Instance profile management is per-cluster — Karpenter creates one
  # profile per NodeClass and tags it with the cluster name.
  statement {
    sid       = "AllowScopedInstanceProfileCreate"
    actions   = ["iam:CreateInstanceProfile", "iam:TagInstanceProfile"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/karpenter.sh/cluster"
      values   = [var.cluster_name]
    }
  }

  statement {
    sid       = "AllowScopedInstanceProfileMutation"
    actions   = ["iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile", "iam:DeleteInstanceProfile", "iam:GetInstanceProfile"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/karpenter.sh/cluster"
      values   = [var.cluster_name]
    }
  }

  statement {
    sid       = "AllowInterruptionQueueActions"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueUrl", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
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
