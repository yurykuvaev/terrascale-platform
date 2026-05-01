# Spot interruption queue. EventBridge fans events from EC2 (instance state
# changes, spot interruption warnings, scheduled events) into SQS; Karpenter
# consumes them and gracefully drains affected nodes.

resource "aws_sqs_queue" "interruption" {
  name                      = "${var.cluster_name}-karpenter-interruption"
  message_retention_seconds = var.interruption_queue_message_retention_seconds

  sqs_managed_sse_enabled = true

  tags = var.tags
}

data "aws_iam_policy_document" "interruption_queue" {
  statement {
    sid       = "AllowEventBridgeServices"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.interruption.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }
  }
}

resource "aws_sqs_queue_policy" "interruption" {
  queue_url = aws_sqs_queue.interruption.url
  policy    = data.aws_iam_policy_document.interruption_queue.json
}

locals {
  interruption_event_rules = {
    spot_interruption = {
      description = "Spot interruption warnings"
      pattern = jsonencode({
        source      = ["aws.ec2"]
        detail-type = ["EC2 Spot Instance Interruption Warning"]
      })
    }
    rebalance_recommendation = {
      description = "Spot rebalance recommendations"
      pattern = jsonencode({
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance Rebalance Recommendation"]
      })
    }
    instance_state_change = {
      description = "Instance state changes"
      pattern = jsonencode({
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance State-change Notification"]
      })
    }
    scheduled_change = {
      description = "AWS health scheduled events"
      pattern = jsonencode({
        source      = ["aws.health"]
        detail-type = ["AWS Health Event"]
      })
    }
  }
}

resource "aws_cloudwatch_event_rule" "interruption" {
  for_each = local.interruption_event_rules

  name          = "${var.cluster_name}-karpenter-${each.key}"
  description   = each.value.description
  event_pattern = each.value.pattern

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "interruption" {
  for_each = local.interruption_event_rules

  rule      = aws_cloudwatch_event_rule.interruption[each.key].name
  target_id = "karpenter-interruption-queue"
  arn       = aws_sqs_queue.interruption.arn
}
