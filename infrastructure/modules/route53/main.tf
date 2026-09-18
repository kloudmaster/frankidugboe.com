resource "aws_route53_zone" "this" {
  name          = var.domain_name
  force_destroy = false

  tags = {
    Name        = var.domain_name
    Project     = "frankidugboe.com"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
