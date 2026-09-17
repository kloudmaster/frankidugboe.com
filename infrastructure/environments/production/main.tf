data "aws_caller_identity" "current" {}

locals {
  origin_bucket_name = "${replace(var.domain_name, ".", "-")}-origin-${data.aws_caller_identity.current.account_id}"
}

module "route53" {
  source = "../../modules/route53"

  domain_name = var.domain_name
}

module "acm" {
  source = "../../modules/acm"

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  route53_zone_id           = module.route53.zone_id
}

module "s3" {
  source = "../../modules/s3"

  bucket_name = local.origin_bucket_name
}
