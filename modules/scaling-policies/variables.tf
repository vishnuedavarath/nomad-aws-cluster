variable "project_name" {
  type = string
}

variable "artifacts_bucket_name" {
  type        = string
  description = "S3 bucket name for storing artifacts"
}

variable "policies_dir" {
  type        = string
  description = "Path to the local directory containing scaling policy HCL files"
}
