variable "project_name" {
  type = string
}

variable "client_asg_arn" {
  type        = string
  description = "ARN of the Nomad client ASG that the autoscaler can modify"
}

variable "server_iam_role_name" {
  type        = string
  description = "Name of the server IAM role to attach autoscaler permissions to"
}

variable "client_iam_role_name" {
  type        = string
  description = "Name of the client IAM role to attach autoscaler permissions to"
}
