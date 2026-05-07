output "asg_name" {
  value = aws_autoscaling_group.server.name
}

output "asg_arn" {
  value = aws_autoscaling_group.server.arn
}

output "launch_template_id" {
  value = aws_launch_template.server.id
}
