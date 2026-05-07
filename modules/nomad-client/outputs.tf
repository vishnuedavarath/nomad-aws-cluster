output "asg_name" {
  value = aws_autoscaling_group.client.name
}

output "asg_arn" {
  value = aws_autoscaling_group.client.arn
}

output "launch_template_id" {
  value = aws_launch_template.client.id
}
