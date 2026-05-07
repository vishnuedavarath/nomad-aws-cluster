# IAM role for the Nomad Autoscaler (runs as a Nomad job)
# Permissions based on actual AWS API calls in the autoscaler codebase

locals {
  autoscaler_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:DeleteTags",
        ]
        Resource = var.client_asg_arn
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeInstanceRefreshes",
          "autoscaling:DescribeTags",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "autoscaler" {
  name = "${var.project_name}-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "autoscaler" {
  name   = "${var.project_name}-autoscaler-policy"
  role   = aws_iam_role.autoscaler.id
  policy = local.autoscaler_policy
}

resource "aws_iam_role_policy" "client_autoscaler" {
  name   = "${var.project_name}-client-autoscaler-policy"
  role   = var.client_iam_role_name
  policy = local.autoscaler_policy
}

resource "aws_iam_role_policy" "server_autoscaler" {
  name   = "${var.project_name}-server-autoscaler-policy"
  role   = var.server_iam_role_name
  policy = local.autoscaler_policy
}
