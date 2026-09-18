resource "aws_route53_record" "apex_a" {
  zone_id = module.route53.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = module.route53.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  zone_id = module.route53.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  zone_id = module.route53.zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }
}
