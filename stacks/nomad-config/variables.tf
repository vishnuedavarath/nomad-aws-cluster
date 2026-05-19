variable "nomad_namespaces" {
  description = "Nomad namespaces to create and configure for the autoscaler"
  type = list(object({
    name        = string
    description = optional(string, "")
  }))
  default = []
}

variable "create_acl_policy" {
  description = "Whether to create an ACL policy granting autoscaler access to namespaces"
  type        = bool
  default     = true
}

variable "acl_policy_name" {
  description = "Name of the ACL policy to create"
  type        = string
  default     = "autoscaler-namespaces"
}

variable "acl_capabilities" {
  description = "Nomad namespace capabilities granted to the autoscaler"
  type        = list(string)
  default     = ["list-jobs", "read-job", "scale-job", "submit-job", "list-scaling-policies", "read-scaling-policy"]
}
