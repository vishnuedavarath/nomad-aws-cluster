variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "nomad-cluster"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "server_instance_type" {
  type    = string
  default = "t3.small"
}

variable "client_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "client_count" {
  type    = number
  default = 2
}

variable "client_min" {
  type    = number
  default = 1
}

variable "client_max" {
  type    = number
  default = 5
}

variable "nomad_token_ssm_prefix" {
  type    = string
  default = "/nomad-cluster/acl"
}
