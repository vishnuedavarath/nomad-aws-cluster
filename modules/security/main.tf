# --- Security Groups ---

resource "aws_security_group" "nomad_server" {
  name_prefix = "${var.project_name}-server-"
  vpc_id      = var.vpc_id
  description = "Nomad server security group"

  # Nomad RPC
  ingress {
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Nomad RPC"
  }

  # Nomad Serf TCP
  ingress {
    from_port   = 4648
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Nomad Serf TCP"
  }

  # Nomad Serf UDP
  ingress {
    from_port   = 4648
    to_port     = 4648
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Nomad Serf UDP"
  }

  # Nomad HTTP API (internal only)
  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Nomad HTTP API"
  }

  # Consul ports
  ingress {
    from_port   = 8300
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Consul server RPC and Serf"
  }

  ingress {
    from_port   = 8301
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Consul Serf UDP"
  }

  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Consul HTTP API"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-server-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "nomad_client" {
  name_prefix = "${var.project_name}-client-"
  vpc_id      = var.vpc_id
  description = "Nomad client security group"

  # Allow all traffic between client nodes (Prometheus, Docker networking, etc.)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "All traffic between clients"
  }

  # Nomad HTTP API (from VPC - servers and other clients)
  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Nomad HTTP API"
  }

  # Nomad client RPC from servers
  ingress {
    from_port       = 4647
    to_port         = 4647
    protocol        = "tcp"
    security_groups = [aws_security_group.nomad_server.id]
    description     = "Nomad RPC from servers"
  }

  # Nomad Serf TCP
  ingress {
    from_port   = 4648
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Nomad Serf TCP"
  }

  # Nomad Serf UDP
  ingress {
    from_port   = 4648
    to_port     = 4648
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Nomad Serf UDP"
  }

  # Dynamic port range for Nomad tasks
  ingress {
    from_port   = 20000
    to_port     = 32000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Nomad dynamic ports"
  }

  # Consul ports
  ingress {
    from_port   = 8300
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Consul server RPC and Serf"
  }

  ingress {
    from_port   = 8301
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Consul Serf UDP"
  }

  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Consul HTTP API"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-client-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- IAM Roles ---

# Nomad Server IAM Role
resource "aws_iam_role" "nomad_server" {
  name = "${var.project_name}-server-role"

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

resource "aws_iam_role_policy" "nomad_server" {
  name = "${var.project_name}-server-policy"
  role = aws_iam_role.nomad_server.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "autoscaling:DescribeAutoScalingGroups",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "server_ssm" {
  role       = aws_iam_role.nomad_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nomad_server" {
  name = "${var.project_name}-server-profile"
  role = aws_iam_role.nomad_server.name
}

# Nomad Client IAM Role
resource "aws_iam_role" "nomad_client" {
  name = "${var.project_name}-client-role"

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

resource "aws_iam_role_policy" "nomad_client" {
  name = "${var.project_name}-client-policy"
  role = aws_iam_role.nomad_client.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "client_ssm" {
  role       = aws_iam_role.nomad_client.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nomad_client" {
  name = "${var.project_name}-client-profile"
  role = aws_iam_role.nomad_client.name
}
