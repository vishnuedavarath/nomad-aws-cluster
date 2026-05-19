terraform {
  backend "s3" {
    bucket  = "nomad-cluster-tf-state"
    key     = "nomad-config/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
