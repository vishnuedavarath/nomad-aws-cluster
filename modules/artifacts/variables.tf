variable "project_name" {
  type = string
}

variable "client_iam_role_name" {
  type        = string
  description = "Name of the client IAM role to attach S3 read permissions to"
}
