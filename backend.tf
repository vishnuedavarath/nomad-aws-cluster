terraform {
  backend "s3" {
    bucket         = "nomad-cluster-tf-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "nomad-cluster-tf-locks"
    encrypt        = true
  }
}
