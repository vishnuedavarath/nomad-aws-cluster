variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "client_count" {
  type    = number
  default = 2
}

variable "min_clients" {
  type    = number
  default = 1
}

variable "max_clients" {
  type    = number
  default = 5
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "spot_instance_types" {
  type    = list(string)
  default = ["t3.medium", "t3a.medium", "t2.medium"]
}

variable "on_demand_base_capacity" {
  type    = number
  default = 0
}

variable "on_demand_percentage" {
  type    = number
  default = 0
}

variable "ami_id" {
  type    = string
  default = ""
}

variable "architecture" {
  type    = string
  default = "amd64"
}

variable "root_volume_size" {
  type    = number
  default = 30
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "node_class" {
  type        = string
  default     = "worker"
  description = "Nomad client node_class for scheduling constraints"
}

variable "name_suffix" {
  type        = string
  default     = "client"
  description = "Suffix for resource names (e.g. client, autoscaler)"
}
