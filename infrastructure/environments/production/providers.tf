provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "frankidugboe.com"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}
