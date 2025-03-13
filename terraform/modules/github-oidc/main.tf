data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = var.tags
}

locals {
  # Flatten the trusted_repos map of lists into a single list of subject claims.
  trusted_subjects = flatten([
    for repo, subjects in var.trusted_repos : [
      for s in subjects : s
    ]
  ])
}

# ---------- Plan role (PRs) ---------------------------------------------------
data "aws_iam_policy_document" "plan_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        for repo, _ in var.trusted_repos : "repo:${var.github_owner}/${repo}:pull_request"
      ]
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = var.plan_role_name
  assume_role_policy = data.aws_iam_policy_document.plan_assume.json
  max_session_duration = 3600
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---------- Apply role (main only) -------------------------------------------
data "aws_iam_policy_document" "apply_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        for repo, _ in var.trusted_repos : "repo:${var.github_owner}/${repo}:ref:refs/heads/main"
      ]
    }
  }
}

resource "aws_iam_role" "apply" {
  name               = var.apply_role_name
  assume_role_policy = data.aws_iam_policy_document.apply_assume.json
  max_session_duration = 3600
  tags               = var.tags
}

# Apply role gets PowerUser + IAM full (Terraform creates roles). Tighten
# this once we have a clear list of services we don't touch.
resource "aws_iam_role_policy_attachment" "apply_power" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy_attachment" "apply_iam" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

# ---------- Image publish role -----------------------------------------------
data "aws_iam_policy_document" "image_publish_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        for repo, _ in var.trusted_repos : "repo:${var.github_owner}/${repo}:ref:refs/heads/main"
      ]
    }
  }
}

resource "aws_iam_role" "image_publish" {
  name               = var.image_publish_role_name
  assume_role_policy = data.aws_iam_policy_document.image_publish_assume.json
  max_session_duration = 3600
  tags               = var.tags
}

data "aws_iam_policy_document" "image_publish" {
  statement {
    sid       = "AllowEcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid = "AllowEcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
    ]
    resources = length(var.ecr_repository_arns) > 0 ? var.ecr_repository_arns : ["*"]
  }
}

resource "aws_iam_policy" "image_publish" {
  name   = "${var.image_publish_role_name}-policy"
  policy = data.aws_iam_policy_document.image_publish.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "image_publish" {
  role       = aws_iam_role.image_publish.name
  policy_arn = aws_iam_policy.image_publish.arn
}
