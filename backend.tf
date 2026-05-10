terraform {
  backend "s3" {
    bucket       = "shopflow-terraform-state-390449413955"
    key          = "shopflow/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
