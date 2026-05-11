output "server_asg_name" {
  value = module.nomad_server.asg_name
}

output "client_asg_name" {
  value = module.nomad_client.asg_name
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "nomad_management_token_ssm_parameter" {
  value = aws_ssm_parameter.nomad_management_token.name
}

output "nomad_admin_token_ssm_parameter" {
  value = aws_ssm_parameter.nomad_admin_token.name
}

output "nomad_operator_token_ssm_parameter" {
  value = aws_ssm_parameter.nomad_operator_token.name
}

output "nomad_autoscaler_token_ssm_parameter" {
  value = aws_ssm_parameter.nomad_autoscaler_token.name
}

output "artifacts_bucket_name" {
  value = module.artifacts.bucket_name
}

output "autoscaler_binary_url" {
  value = module.artifacts.autoscaler_binary_url
}

output "scaling_policies_url" {
  value = module.scaling_policies.policies_s3_url
}
