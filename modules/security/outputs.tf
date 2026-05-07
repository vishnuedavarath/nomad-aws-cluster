output "server_security_group_id" {
  value = aws_security_group.nomad_server.id
}

output "client_security_group_id" {
  value = aws_security_group.nomad_client.id
}

output "server_instance_profile_name" {
  value = aws_iam_instance_profile.nomad_server.name
}

output "client_instance_profile_name" {
  value = aws_iam_instance_profile.nomad_client.name
}

output "server_iam_role_arn" {
  value = aws_iam_role.nomad_server.arn
}

output "client_iam_role_arn" {
  value = aws_iam_role.nomad_client.arn
}

output "client_iam_role_name" {
  value = aws_iam_role.nomad_client.name
}
