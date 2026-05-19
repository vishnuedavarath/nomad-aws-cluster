data "aws_ami" "hc_base_ubuntu" {
  most_recent = true
  owners      = ["888995627335"] # HashiCorp ami-prod account

  filter {
    name   = "name"
    values = [format("hc-base-ubuntu-2404-%s-*", var.architecture)]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_launch_template" "server" {
  name_prefix   = "${var.project_name}-server-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.hc_base_ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.security_group_id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    server_count = var.server_count
    region       = var.region
    project_name = var.project_name
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 enforced
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-server"
      Role = "nomad-server"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "server" {
  name                = "${var.project_name}-server-asg"
  desired_capacity    = var.server_count
  min_size            = var.server_count
  max_size            = var.server_count
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.server.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "NomadRole"
    value               = "server"
    propagate_at_launch = true
  }

  force_delete = true

  lifecycle {
    create_before_destroy = true
  }
}
