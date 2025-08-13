

terraform {
  backend "s3" {
    bucket = "ttt-my-terraform-state"
    key = "clean_prd_ecomm/s3/terraform.tfstate"
    region = "eu-central-1"
    use_lockfile = true
  }
}