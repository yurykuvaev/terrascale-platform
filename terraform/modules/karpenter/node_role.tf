# IAM role assumed by every Karpenter-provisioned EC2 instance. The cluster
# must trust it via an EKS access entry of type EC2_LINUX (handled in the
# parent EKS configuration via var.access_entries).

data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = var.node_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
  tags               = var.tags
}

# Standard EKS worker permissions plus SSM for break-glass access.
locals {
  node_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset(local.node_managed_policies)

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "node" {
  name = aws_iam_role.node.name
  role = aws_iam_role.node.name
  tags = var.tags
}
