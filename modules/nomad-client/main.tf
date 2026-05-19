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

resource "aws_launch_template" "client" {
  name_prefix   = "${var.project_name}-${var.name_suffix}-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.hc_base_ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.security_group_id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    region       = var.region
    project_name = var.project_name
    node_class   = var.node_class
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
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
      Name      = "${var.project_name}-${var.name_suffix}"
      Role      = "nomad-client"
      NodeClass = var.node_class
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "client" {
  name                = "${var.project_name}-${var.name_suffix}-asg"
  desired_capacity    = var.client_count
  min_size            = var.min_clients
  max_size            = var.max_clients
  vpc_zone_identifier = var.subnet_ids

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.client.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.spot_instance_types
        content {
          instance_type = override.value
        }
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = var.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = var.on_demand_percentage
      spot_allocation_strategy                 = "capacity-optimized"
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.name_suffix}"
    propagate_at_launch = true
  }

  tag {
    key                 = "NomadRole"
    value               = "client"
    propagate_at_launch = true
  }

  force_delete = true

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
