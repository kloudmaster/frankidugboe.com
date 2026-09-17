terraform {
  backend "s3" {
    bucket       = "frankidugboe-com-terraform-state-216066926519"
    key          = "production/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
