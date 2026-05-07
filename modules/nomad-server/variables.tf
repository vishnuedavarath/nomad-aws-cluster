variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "server_count" {
  type    = number
  default = 3
}

variable "instance_type" {
  type    = string
  default = "t3.small"
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
  default = 20
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
