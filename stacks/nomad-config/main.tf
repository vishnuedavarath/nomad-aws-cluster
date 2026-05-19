module "namespaces" {
  source = "../../modules/namespaces"

  namespaces        = var.nomad_namespaces
  create_acl_policy = var.create_acl_policy && length(var.nomad_namespaces) > 0
  acl_policy_name   = var.acl_policy_name
  acl_capabilities  = var.acl_capabilities
}
