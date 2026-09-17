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
