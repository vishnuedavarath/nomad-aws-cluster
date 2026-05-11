module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  availability_zones = var.availability_zones
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = module.networking.vpc_cidr
}

module "nomad_server" {
  source = "./modules/nomad-server"

  project_name          = var.project_name
  region                = var.region
  server_count          = 3
  instance_type         = var.server_instance_type
  subnet_ids            = module.networking.public_subnet_ids
  security_group_id     = module.security.server_security_group_id
  instance_profile_name = module.security.server_instance_profile_name
}

module "nomad_client" {
  source = "./modules/nomad-client"

  project_name          = var.project_name
  region                = var.region
  client_count          = var.client_count
  min_clients           = var.client_min
  max_clients           = var.client_max
  instance_type         = var.client_instance_type
  subnet_ids            = module.networking.public_subnet_ids
  security_group_id     = module.security.client_security_group_id
  instance_profile_name = module.security.client_instance_profile_name
}

module "autoscaler" {
  source = "./modules/autoscaler"

  project_name         = var.project_name
  client_asg_arn       = module.nomad_client.asg_arn
  server_iam_role_name = "${var.project_name}-server-role"
  client_iam_role_name = module.security.client_iam_role_name

  depends_on = [module.nomad_client]
}

module "artifacts" {
  source = "./modules/artifacts"

  project_name         = var.project_name
  client_iam_role_name = module.security.client_iam_role_name
}

module "scaling_policies" {
  source = "./modules/scaling-policies"

  project_name          = var.project_name
  artifacts_bucket_name = module.artifacts.bucket_name
  policies_dir          = "${path.root}/scaling-policies"
}

locals {
  nomad_management_token_param = "${var.nomad_token_ssm_prefix}/management-token"
  nomad_operator_token_param   = "${var.nomad_token_ssm_prefix}/operator-token"
  nomad_autoscaler_token_param = "${var.nomad_token_ssm_prefix}/autoscaler-token"
}

resource "aws_ssm_parameter" "nomad_management_token" {
  name  = local.nomad_management_token_param
  type  = "SecureString"
  value = "bootstrap-pending"

  tags = {
    Name    = "${var.project_name}-nomad-management-token"
    Project = var.project_name
  }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "nomad_operator_token" {
  name  = local.nomad_operator_token_param
  type  = "SecureString"
  value = "bootstrap-pending"

  tags = {
    Name    = "${var.project_name}-nomad-operator-token"
    Project = var.project_name
  }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "nomad_autoscaler_token" {
  name  = local.nomad_autoscaler_token_param
  type  = "SecureString"
  value = "bootstrap-pending"

  tags = {
    Name    = "${var.project_name}-nomad-autoscaler-token"
    Project = var.project_name
  }

  lifecycle {
    ignore_changes = [value]
  }
}
