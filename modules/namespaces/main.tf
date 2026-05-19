terraform {
  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.0"
    }
  }
}

resource "nomad_namespace" "this" {
  for_each = { for ns in var.namespaces : ns.name => ns }

  name        = each.value.name
  description = lookup(each.value, "description", "")
}

# ACL policy granting autoscaler access to all managed namespaces
resource "nomad_acl_policy" "autoscaler_namespaces" {
  count = var.create_acl_policy ? 1 : 0

  name        = var.acl_policy_name
  description = "Grants autoscaler read/scale access to managed namespaces"

  rules_hcl = join("\n\n", [
    for ns in var.namespaces : <<-EOT
      namespace "${ns.name}" {
        policy       = "read"
        capabilities = ${jsonencode(var.acl_capabilities)}
      }
    EOT
  ])
}
